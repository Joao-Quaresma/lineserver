require "rails_helper"

RSpec.describe UploadedFileManager, type: :service do
  let!(:uploaded_file) { create(:uploaded_file) }
  let(:file_path) { Rails.root.join("spec/fixtures/files/testfile.txt") }
  let(:valid_file) { fixture_file_upload(file_path, "text/plain") }
  let(:file_id) { uploaded_file.id }
  let(:line_number) { 3 }
  let(:line_content) { "This is line 3" }

  before do
    allow(FileStorageService).to receive(:save_file).and_return(file_path)
    allow(FileStorageService).to receive(:count_lines_and_offsets).and_return({ line_count: 6, offsets: { 1 => 0, 2 => 23, 3 => 39, 4 => 69, 5 => 90, 6 => 106 } })
    allow(FileStorageService).to receive(:file_exists?).and_return(true)
    allow(FileStorageService).to receive(:get_file_path).and_return(file_path)
    allow(FileStorageService).to receive(:read_line).and_return(line_content)
    allow(FileStorageService).to receive(:delete_file)

    allow(RedisCache).to receive(:hset)
    allow(RedisCache).to receive(:hget).and_return("39")
    allow(RedisCache).to receive(:get).and_return(nil)
    allow(RedisCache).to receive(:set)
    allow(RedisCache).to receive(:delete)
    allow(RedisCache).to receive(:hdel)
  end

  describe ".create_uploaded_file" do
    it "creates a file record and saves offsets in Redis" do
      result = UploadedFileManager.create_uploaded_file(valid_file)

      expect(result).to include(:id, :name, :size, :line_count)
      expect(result[:line_count]).to eq(6)

      expect(FileStorageService).to have_received(:save_file).once
      expect(FileStorageService).to have_received(:count_lines_and_offsets).once
      expect(RedisCache).to have_received(:hset).at_least(:once)
      expect(RedisCache).to have_received(:delete).with("files:list")
    end

    it "returns an error if no file is provided" do
      result = UploadedFileManager.create_uploaded_file(nil)

      expect(result).to eq({ error: "No file uploaded" })
    end
  end

  describe ".fetch_file_list" do
    it "returns a list of files from Redis if cached" do
      cached_files = [ { id: file_id, name: "testfile.txt", size: 122, line_count: 6 } ].to_json
      allow(RedisCache).to receive(:get).with("files:list").and_return(cached_files)

      result = UploadedFileManager.fetch_file_list

      expect(result).to be_an(Array)
      expect(result.first).to include("id" => file_id)
      expect(RedisCache).to have_received(:get).with("files:list")
    end

    it "fetches from the database if cache is empty" do
      allow(RedisCache).to receive(:get).with("files:list").and_return(nil)

      result = UploadedFileManager.fetch_file_list

      expect(result).to be_an(Array)
      expect(RedisCache).to have_received(:set).with("files:list", any_args, 300)
    end
  end

  describe ".fetch_line_from_file" do
    it "retrieves a specific line from Redis cache if available" do
      allow(RedisCache).to receive(:get).with("line:#{file_id}:#{line_number}").and_return(line_content)

      result, status = UploadedFileManager.fetch_line_from_file(file_id, line_number)

      expect(status).to eq(:ok)
      expect(result).to eq({ id: file_id, line: line_content })
      expect(FileStorageService).not_to have_received(:read_line)
    end

    it "reads line from file and caches it if not cached" do
      allow(RedisCache).to receive(:get).with("line:#{file_id}:#{line_number}").and_return(nil)

      result, status = UploadedFileManager.fetch_line_from_file(file_id, line_number)

      expect(status).to eq(:ok)
      expect(result[:line]).to eq(line_content)
      expect(RedisCache).to have_received(:set).with("line:#{file_id}:#{line_number}", line_content, 300)
    end

    it "returns an error if file is not found" do
      result, status = UploadedFileManager.fetch_line_from_file("non_existent_id", line_number)

      expect(status).to eq(:not_found)
      expect(result).to eq({ error: "File not found" })
    end

    it "returns an error if line number is invalid" do
      result, status = UploadedFileManager.fetch_line_from_file(file_id, -1)

      expect(status).to eq(:bad_request)
      expect(result).to eq({ error: "Invalid line number" })
    end

    it "returns an error if requested line exceeds file length" do
      allow(RedisCache).to receive(:hget).with("file:#{file_id}", 999).and_return(nil)

      result, status = UploadedFileManager.fetch_line_from_file(file_id, 999)

      expect(status).to eq(:payload_too_large)
      expect(result).to eq({ error: "Requested line exceeds file length" })
    end
  end

  describe ".delete_uploaded_file" do
    it "deletes a file and clears Redis cache" do
      result, status = UploadedFileManager.delete_uploaded_file(file_id)

      expect(status).to eq(:ok)
      expect(result).to eq({ message: "File deleted successfully" })

      expect(FileStorageService).to have_received(:delete_file).once
      expect(RedisCache).to have_received(:hdel).with("file:#{file_id}")
      expect(RedisCache).to have_received(:delete).with("files:list")
    end

    it "returns an error if file is not found" do
      result, status = UploadedFileManager.delete_uploaded_file("non_existent_id")

      expect(status).to eq(:not_found)
      expect(result).to eq({ error: "File not found" })
    end

    it "returns an error if file is already deleted" do
      allow(FileStorageService).to receive(:file_exists?).and_return(false)

      result, status = UploadedFileManager.delete_uploaded_file(file_id)

      expect(status).to eq(:gone)
      expect(result).to eq({ error: "File already deleted" })
    end
  end
end

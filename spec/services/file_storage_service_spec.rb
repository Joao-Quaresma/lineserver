require "rails_helper"

RSpec.describe FileStorageService, type: :service do
  let(:file_id) { SecureRandom.uuid }
  let(:storage_path) { Rails.root.join("storage", "uploads") }
  let(:file_path) { storage_path.join("#{file_id}.txt") }
  let(:test_file_path) { Rails.root.join("spec/fixtures/files/testfile.txt") }

  before do
    FileUtils.mkdir_p(storage_path)
    FileUtils.cp(test_file_path, file_path)
  end

  after do
    FileUtils.rm_f(file_path)
  end

  describe ".save_file" do
    it "saves the uploaded file with the correct name" do
      uploaded_file = fixture_file_upload(test_file_path, "text/plain")

      saved_path = FileStorageService.save_file(uploaded_file, file_id)

      expect(saved_path.to_s).to eq(file_path.to_s)
      expect(File).to exist(saved_path)
    end
  end

  describe ".count_lines_and_offsets" do
    it "counts lines and calculates offsets correctly" do
      result = FileStorageService.count_lines_and_offsets(file_path)

      expect(result[:line_count]).to eq(5)
      expect(result[:offsets]).to be_a(Hash)
      expect(result[:offsets].keys).to include(1, 2, 3, 4, 5)
    end
  end

  describe ".read_line" do
    it "reads a specific line from the file" do
      offsets = FileStorageService.count_lines_and_offsets(file_path)[:offsets]
      line_number = 3
      selected_line = FileStorageService.read_line(file_path, offsets[line_number])

      expect(selected_line).to eq("Line 3")
    end
  end

  describe ".file_exists?" do
    it "returns true if the file exists" do
      expect(FileStorageService.file_exists?(file_id)).to be true
    end

    it "returns false if the file does not exist" do
      expect(FileStorageService.file_exists?("non_existent_id")).to be false
    end
  end

  describe ".get_file_path" do
    it "returns the correct file path for an existing file" do
      expect(FileStorageService.get_file_path(file_id)).to eq(file_path.to_s)
    end

    it "returns nil if the file does not exist" do
      expect(FileStorageService.get_file_path("non_existent_id")).to be_nil
    end
  end

  describe ".delete_file" do
    it "deletes the file successfully" do
      expect(File).to exist(file_path)

      FileStorageService.delete_file(file_id)

      expect(File).not_to exist(file_path)
    end

    it "does not raise an error if file does not exist" do
      expect { FileStorageService.delete_file("non_existent_id") }.not_to raise_error
    end
  end
end

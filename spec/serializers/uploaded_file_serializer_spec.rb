require "rails_helper"

RSpec.describe UploadedFileSerializer, type: :serializer do
  let(:file) { create(:uploaded_file, created_at: Time.utc(2025, 2, 15, 12, 0, 0)) }
  let(:serialized_file) { UploadedFileSerializer.one(file) }

  describe "attributes" do
    it "includes id, name, size, line_count, and created_at" do
      expect(serialized_file.keys).to match_array(%i[id name size line_count created_at])
    end

    it "correctly serializes the id" do
      expect(serialized_file[:id]).to eq(file.id)
    end

    it "correctly serializes the name" do
      expect(serialized_file[:name]).to eq(file.name)
    end

    it "correctly serializes the size" do
      expect(serialized_file[:size]).to eq(file.size)
    end

    it "correctly serializes the line_count" do
      expect(serialized_file[:line_count]).to eq(file.line_count)
    end

    it "formats created_at in ISO 8601 format" do
      expect(serialized_file[:created_at]).to eq("2025-02-15T12:00:00Z")
    end
  end

  describe "multiple file serialization" do
    let(:files) { create_list(:uploaded_file, 3) }
    let(:serialized_files) { UploadedFileSerializer.many(files) }

    it "serializes multiple files correctly" do
      expect(serialized_files).to be_an(Array)
      expect(serialized_files.size).to eq(3)
      expect(serialized_files.first.keys).to match_array(%i[id name size line_count created_at])
    end
  end
end

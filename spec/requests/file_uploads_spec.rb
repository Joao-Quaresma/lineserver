require "swagger_helper"

RSpec.describe "File Uploads API", type: :request do
  path "/file_uploads" do
    post "Upload a file" do
      tags "File Uploads"
      consumes "multipart/form-data"
      parameter name: :file, in: :formData, type: :file, required: true

      response "success", "File uploaded successfully" do
        let(:file) { fixture_file_upload(Rails.root.join("spec/fixtures/files/testfile.txt"), "text/plain") }

        before do
          post "/file_uploads.json", params: { file: file }
        end

        it "returns a JSON response with file details" do
          json_response = JSON.parse(response.body)
          expect(json_response).to include("id", "name", "size", "line_count")
        end
      end

      response "error", "No file uploaded" do
        let(:file) { nil }

        before do
          post "/file_uploads.json", params: {}
        end

        it "returns an error message in JSON" do
          expect(response.body).to include("No file uploaded")
        end
      end
    end

    get "List all uploaded files" do
      tags "File Uploads"
      produces "application/json"

      response "200", "Files listed successfully" do
        before do
          get "/file_uploads.json"
        end

        it "returns a JSON list of files" do
          expect(response.body).to match(/\[.*\]/)
        end
      end
    end
  end

  path "/file_uploads/{id}/line/{line}" do
    get "Get a specific line from a file" do
      tags "File Uploads"
      produces "application/json"
      parameter name: :id, in: :path, type: :string, required: true
      parameter name: :line, in: :path, type: :integer, required: true

      response "200", "Line retrieved successfully" do
        let!(:file) { create(:uploaded_file, line_count: 10) }
        let(:id) { file.id }
        let(:line) { 1 }

        before do
          allow(UploadedFileManager).to receive(:fetch_line_from_file)
            .with(id, line)
            .and_return([ { id: file.id, line: "Example Line" }, :ok ])
        end

        run_test!
      end

      response "404", "File not found" do
        let(:id) { "non-existent-id" }
        let(:line) { 1 }

        before do
          allow(UploadedFileManager).to receive(:fetch_line_from_file)
            .with(id, line)
            .and_return([ { error: "File not found" }, :not_found ])
        end

        run_test!
      end

      response "413", "Requested line is out of range" do
        let!(:file) { create(:uploaded_file, line_count: 5) }
        let(:id) { file.id }
        let(:line) { 999 }

        before do
          allow(UploadedFileManager).to receive(:fetch_line_from_file)
            .with(id, line)
            .and_return([ { error: "Requested line exceeds file length" }, :payload_too_large ])
        end

        run_test!
      end
    end
  end
end

require "rails_helper"

RSpec.describe FileUploadsController, type: :request do
  let!(:uploaded_file) { create(:uploaded_file) }
  let(:file_path) { Rails.root.join("spec/fixtures/files/testfile.txt") }
  let(:valid_file) { fixture_file_upload(file_path, "text/plain") }

  before do
    allow(UploadedFileManager).to receive(:create_uploaded_file).and_return(
      { id: uploaded_file.id, name: "testfile.txt", size: 122, line_count: 6 }
    )
    allow(UploadedFileManager).to receive(:fetch_file_list).and_return([
      { id: uploaded_file.id, name: "testfile.txt", size: 122, line_count: 6 }
    ])
    allow(UploadedFileManager).to receive(:fetch_line_from_file).and_return([ { id: uploaded_file.id, line: "This is line 3" }, :ok ])
    allow(UploadedFileManager).to receive(:delete_uploaded_file).and_return({ message: "File deleted successfully" })
  end

  describe "POST /file_uploads" do
    it "uploads a file successfully" do
      post "/file_uploads", params: { file: valid_file }

      expect(response).to have_http_status(:found) # Expect redirect
      follow_redirect! # Follow the redirect

      expect(response.body).to include("File uploaded successfully!")
    end

    it "returns error when no file is uploaded" do
      post "/file_uploads", params: {}, headers: { "ACCEPT" => "application/json" }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)).to eq({ "error" => "No file uploaded" })
    end
  end

  describe "GET /file_uploads" do
    it "returns a list of uploaded files as JSON" do
      get "/file_uploads", headers: { "ACCEPT" => "application/json" }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to be_an(Array)
    end
  end

  describe "GET /file_uploads/:id/line/:line_number" do
    it "returns the requested line from a file" do
      get "/file_uploads/#{uploaded_file.id}/line/3"

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq({ "id" => uploaded_file.id, "line" => "This is line 3" })
    end

    it "returns an error when the line number is out of range" do
      allow(UploadedFileManager).to receive(:fetch_line_from_file).and_return([ { error: "Requested line exceeds file length" }, :payload_too_large ])

      get "/file_uploads/#{uploaded_file.id}/line/999"

      expect(response).to have_http_status(:payload_too_large)
      expect(JSON.parse(response.body)).to eq({ "error" => "Requested line exceeds file length" })
    end
  end

  describe "DELETE /file_uploads/:id" do
    it "deletes a file successfully" do
      delete "/file_uploads/#{uploaded_file.id}"

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["message"]).to eq("File deleted successfully")
    end

    it "returns an error when trying to delete a non-existent file" do
      allow(UploadedFileManager).to receive(:delete_uploaded_file).and_return([ { error: "File not found" }, :not_found ])

      delete "/file_uploads/non_existent_id"

      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)).to eq({ "error" => "File not found" })
    end
  end
end

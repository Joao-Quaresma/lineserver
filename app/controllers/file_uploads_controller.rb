class FileUploadsController < ApplicationController
  skip_forgery_protection

  # POST /file_uploads
  # Uploads a new file and stores metadata in the database.
  # The file is saved to local storage, and line offsets are cached in Redis.
  #
  # @param file [UploadedFile] The file to be uploaded (multipart/form-data)
  # @return [JSON] Returns file metadata (id, name, size, line_count) on success
  #                Returns { error: "No file uploaded" } with status 422 if no file is provided
  def create
    if params[:file].blank?
      return render json: { error: "No file uploaded" }, status: :unprocessable_entity
    end

    result = UploadedFileManager.create_uploaded_file(params[:file])

    return render json: { error: result[:error] }, status: :unprocessable_entity if result[:error]

    render json: result, status: :created
  end

  # GET /file_uploads
  # Lists all uploaded files with metadata.
  #
  # @return [JSON] Returns an array of uploaded files (id, name, size, line_count, created_at)
  def index
    render json: UploadedFileManager.fetch_file_list
  end
  # def index
  #   @files = UploadedFile.all
  #   respond_to do |format|
  #     format.html # Renders app/views/file_uploads/index.html.erb
  #     format.json { render json: @files }
  #   end
  # end


  # GET /file_uploads/:id?line=:line_number
  # Retrieves a specific line from a file.
  #
  # @param id [UUID] The ID of the uploaded file
  # @param line [Integer] The line number to retrieve (query param)
  # @return [JSON] Returns { id: file_id, line: "Requested line content" } on success (200)
  #                Returns { error: "File not found" } with status 404 if file doesn't exist
  #                Returns { error: "Invalid line number" } with status 400 if line is negative/zero
  #                Returns { error: "Requested line exceeds file length" } with status 413 if out of range
  def show
    result, status = UploadedFileManager.fetch_line_from_file(params[:id], params[:line].to_i)
    render json: result, status: status
  end

  # DELETE /file_uploads/:id
  # Deletes an uploaded file from the system.
  #
  # @param id [UUID] The ID of the file to delete
  # @return [JSON] Returns { message: "File deleted successfully" } on success (200)
  #                Returns { error: "File not found" } with status 404 if file is missing
  #                Returns { error: "File already deleted" } with status 410 if already removed
  def destroy
    result, status = UploadedFileManager.delete_uploaded_file(params[:id])
    render json: result, status: status
  end
end

class FileUploadsController < ApplicationController
  skip_forgery_protection

  def create
    if params[:file].blank?
      return render json: { error: "No file uploaded" }, status: :unprocessable_entity
    end

    result = UploadedFileManager.create_uploaded_file(params[:file])

    return render json: { error: result[:error] }, status: :unprocessable_entity if result[:error]

    render json: result, status: :created
  end


  def index
    render json: UploadedFileManager.fetch_file_list
  end

  def show
    result, status = UploadedFileManager.fetch_line_from_file(params[:id], params[:line].to_i)
    render json: result, status: status
  end

  def destroy
    result, status = UploadedFileManager.delete_uploaded_file(params[:id])
    render json: result, status: status
  end
end

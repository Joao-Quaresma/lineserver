class FileUploadsController < ApplicationController
  skip_forgery_protection

  def create
    result = UploadedFileManager.create_uploaded_file(params[:file])
    return render json: { error: result[:error] }, status: :unprocessable_entity if result[:error]

    render json: result, status: :created
  end

  def index
    render json: UploadedFileManager.fetch_file_list
  end

  def show
    result = UploadedFileManager.fetch_line_from_file(params[:id], params[:line].to_i)
    return render json: { error: result[:error] }, status: :unprocessable_entity if result[:error]

    render json: result
  end

  def destroy
    result = UploadedFileManager.delete_uploaded_file(params[:id])
    return render json: { error: result[:error] }, status: :not_found if result[:error]

    render json: result
  end
end

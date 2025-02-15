class UploadedFileManager
  STORAGE_PATH = Rails.root.join("storage", "uploads")

  def self.create_uploaded_file(uploaded_file)
    return { error: "No file uploaded" } unless uploaded_file

    file_path = STORAGE_PATH.join(uploaded_file.original_filename)

    File.open(file_path, "wb") { |file| file.write(uploaded_file.read) }

    line_count = `wc -l "#{file_path}"`.strip.split.first.to_i

    file_record = UploadedFile.create!(
      name: uploaded_file.original_filename,
      size: uploaded_file.size,
      line_count: line_count
    )

    { id: file_record.id, name: file_record.name, size: file_record.size, line_count: file_record.line_count }
  end

  def self.fetch_file_list
    files = UploadedFile.order(created_at: :desc)
    UploadedFileSerializer.many(files)
  end

  def self.fetch_line_from_file(file_id, line_number)
    file = UploadedFile.find_by(id: file_id)
    return { error: "File not found" } unless file
    return { error: "Invalid line number" } if line_number <= 0

    file_path = Rails.root.join("storage", "uploads", file.name)
    return { error: "File not found on disk" } unless File.exist?(file_path)

    selected_line = nil
    File.foreach(file_path).with_index(1) do |line, index|
      if index == line_number
        selected_line = line.strip
        break
      end
    end

    return { error: "Line number out of range" } unless selected_line

    UploadedFileSerializer.one(file).merge(line: selected_line)
  end


  def self.delete_uploaded_file(file_id)
    file = UploadedFile.find_by(id: file_id)
    return { error: "File not found" } unless file

    file_path = STORAGE_PATH.join(file.name)
    File.delete(file_path) if File.exist?(file_path)

    file.destroy!
    { message: "File deleted successfully" }
  end
end

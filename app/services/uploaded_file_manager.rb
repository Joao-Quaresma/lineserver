class UploadedFileManager
  def self.create_uploaded_file(uploaded_file)
    return { error: "No file uploaded" } unless uploaded_file

    file_record = UploadedFile.create!(
      name: uploaded_file.original_filename,
      size: uploaded_file.size,
      line_count: 0
    )

    file_path = FileStorageService.save_file(uploaded_file, file_record.id)

    file_data = FileStorageService.count_lines_and_offsets(file_path)

    file_record.update!(line_count: file_data[:line_count])

    file_data[:offsets].each { |line_number, offset| RedisCache.hset("file:#{file_record.id}", line_number, offset) }

    RedisCache.delete("files:list")

    {
      id: file_record.id,
      name: file_record.name,
      size: file_record.size,
      line_count: file_record.line_count
    }
  end


  def self.fetch_file_list
    cached_files = RedisCache.get("files:list")
    return Oj.load(cached_files) if cached_files

    files = UploadedFile.order(created_at: :desc)
    serialized_files = UploadedFileSerializer.many(files)

    RedisCache.set("files:list", Oj.dump(serialized_files), 300)
    serialized_files
  end

  def self.fetch_line_from_file(file_id, line_number)
    file = UploadedFile.find_by(id: file_id)
    return { error: "File not found" }, :not_found unless file
    return { error: "Invalid line number" }, :bad_request if line_number <= 0

    return { error: "File not found on disk" }, :not_found unless FileStorageService.file_exists?(file_id)

    offset = RedisCache.hget("file:#{file.id}", line_number)
    return { error: "Requested line exceeds file length" }, :payload_too_large unless offset

    cache_key = "line:#{file.id}:#{line_number}"
    cached_line = RedisCache.get(cache_key)

    if cached_line
      selected_line = cached_line
    else
      file_path = FileStorageService.get_file_path(file_id)
      selected_line = FileStorageService.read_line(file_path, offset)

      RedisCache.set(cache_key, selected_line, 300)
    end

    [ { id: file.id, line: selected_line }, :ok ]
  end


  def self.delete_uploaded_file(file_id)
    file = UploadedFile.find_by(id: file_id)
    return [ { error: "File not found" }, :not_found ] unless file

    if FileStorageService.file_exists?(file.id)
      FileStorageService.delete_file(file.id)
      RedisCache.hdel("file:#{file.id}")
    else
      return [ { error: "File already deleted" }, :gone ]
    end

    RedisCache.delete("files:list")
    file.destroy!

    [ { message: "File deleted successfully" }, :ok ]
  end
end

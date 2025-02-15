class UploadedFileManager
  STORAGE_PATH = Rails.root.join("storage", "uploads")

  def self.create_uploaded_file(uploaded_file)
    return { error: "No file uploaded" } unless uploaded_file

    file_path = STORAGE_PATH.join(uploaded_file.original_filename)

    File.open(file_path, "wb") { |file| file.write(uploaded_file.read) }

    line_count = 0
    offset = 0

    File.open(file_path, "r") do |file|
      file.each_line do |line|
        line_count += 1
        RedisCache.hset("file:#{uploaded_file.original_filename}", line_count, offset)
        offset += line.bytesize
      end
    end

    file_record = UploadedFile.create!(
      name: uploaded_file.original_filename,
      size: uploaded_file.size,
      line_count: line_count
    )

    RedisCache.delete("files:list")

    { id: file_record.id, name: file_record.name, size: file_record.size, line_count: line_count }
  end

  def self.fetch_file_list
    cached_files = RedisCache.get("files:list")

    if cached_files
      puts "DEBUG: Fetching file list from Redis"
      return Oj.load(cached_files)
    end

    files = UploadedFile.order(created_at: :desc)
    serialized_files = UploadedFileSerializer.many(files)

    RedisCache.set("files:list", Oj.dump(serialized_files), 300)

    puts "DEBUG: Fetching file list from DB and caching it"
    serialized_files
  end


  def self.fetch_line_from_file(file_id, line_number)
    file = UploadedFile.find_by(id: file_id)
    return { error: "File not found" } unless file
    return { error: "Invalid line number" } if line_number <= 0

    file_path = STORAGE_PATH.join(file.name)
    return { error: "File not found on disk" } unless File.exist?(file_path)

    offset = RedisCache.hget("file:#{file.name}", line_number)
    return { error: "Line number out of range" } unless offset

    cache_key = "line:#{file.name}:#{line_number}"
    cached_line = RedisCache.get(cache_key)

    if cached_line
      puts "DEBUG: Fetching line from Redis cache"
      selected_line = cached_line
    else
      File.open(file_path, "r") do |file|
        file.seek(offset.to_i)
        selected_line = file.readline.strip
      end

      RedisCache.set(cache_key, selected_line, 300)
      puts "DEBUG: Caching line in Redis"
    end

    UploadedFileSerializer.one(file).merge(line: selected_line)
  end

  def self.delete_uploaded_file(file_id)
    file = UploadedFile.find_by(id: file_id)
    return { error: "File not found" } unless file

    file_path = STORAGE_PATH.join(file.name)
    File.delete(file_path) if File.exist?(file_path)

    RedisCache.hdel("file:#{file.name}")
    RedisCache.delete("files:list")

    file.destroy!
    { message: "File deleted successfully" }
  end
end

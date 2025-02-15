class UploadedFileManager
  STORAGE_PATH = Rails.root.join("storage", "uploads")

  def self.create_uploaded_file(uploaded_file)
    return { error: "No file uploaded" } unless uploaded_file

    file_extension = File.extname(uploaded_file.original_filename)
    temp_filename = SecureRandom.uuid + file_extension
    temp_file_path = STORAGE_PATH.join(temp_filename)

    File.open(temp_file_path, "wb") { |file| file.write(uploaded_file.read) }

    line_count = 0
    offset = 0

    File.open(temp_file_path, "r") do |file|
      file.each_line do |line|
        line_count += 1
        offset += line.bytesize
      end
    end

    file_record = UploadedFile.create!(
      name: uploaded_file.original_filename,
      size: uploaded_file.size,
      line_count: line_count
    )

    unique_filename = "#{file_record.id}#{file_extension}"
    final_file_path = STORAGE_PATH.join(unique_filename)
    File.rename(temp_file_path, final_file_path)

    offset = 0
    File.open(final_file_path, "r") do |file|
      file.each_line.with_index(1) do |line, line_number|
        RedisCache.hset("file:#{file_record.id}", line_number, offset)
        offset += line.bytesize
      end
    end

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

    file_extension = File.extname(file.name)
    unique_filename = "#{file.id}#{file_extension}"
    file_path = STORAGE_PATH.join(unique_filename)

    return { error: "File not found on disk" } unless File.exist?(file_path)

    offset = RedisCache.hget("file:#{file.id}", line_number)
    return { error: "Line number out of range" } unless offset

    cache_key = "line:#{file.id}:#{line_number}"
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

    file_extension = File.extname(file.name)
    unique_filename = "#{file.id}#{file_extension}"
    file_path = STORAGE_PATH.join(unique_filename)

    File.delete(file_path) if File.exist?(file_path)

    RedisCache.hdel("file:#{file.id}")
    RedisCache.delete("files:list")

    file.destroy!
    { message: "File deleted successfully" }
  end
end

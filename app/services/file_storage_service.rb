class FileStorageService
  STORAGE_PATH = Rails.env.test? ? Rails.root.join("tmp", "test_uploads") : Rails.root.join("storage", "uploads")

  def self.save_file(uploaded_file, file_id)
    ensure_storage_directory

    file_extension = File.extname(uploaded_file.original_filename)
    filename = "#{file_id}#{file_extension}"
    file_path = STORAGE_PATH.join(filename)

    File.open(file_path, "wb") { |file| file.write(uploaded_file.read) }
    file_path
  end

  def self.count_lines_and_offsets(file_path)
    line_count = 0
    offset = 0
    offsets = {}

    File.open(file_path, "r") do |file|
      file.each_line.with_index(1) do |line, line_number|
        offsets[line_number] = offset
        offset += line.bytesize
        line_count += 1
      end
    end

    { line_count: line_count, offsets: offsets }
  end

  def self.read_line(file_path, offset)
    File.open(file_path, "r") do |file|
      file.seek(offset.to_i)
      return file.readline.strip
    end
  end

  def self.file_exists?(file_id)
    Dir.glob(STORAGE_PATH.join("#{file_id}.*")).any?
  end

  def self.get_file_path(file_id)
    Dir.glob(STORAGE_PATH.join("#{file_id}.*")).first
  end

  def self.delete_file(file_id)
    file_path = get_file_path(file_id)
    File.delete(file_path) if file_path && File.exist?(file_path)
  end

  private

  def self.ensure_storage_directory
    FileUtils.mkdir_p(STORAGE_PATH) unless Dir.exist?(STORAGE_PATH)
  end
end

class UploadedFileSerializer < Oj::Serializer
  attributes :id, :name, :size, :line_count, :created_at

  def created_at
    object.created_at.iso8601
  end
end

class UploadedFile < ApplicationRecord
  validates :name, presence: true
  validates :size, presence: true, numericality: { greater_than: 0 }
  validates :line_count, presence: true, numericality: { greater_than_or_equal_to: 0 }
end

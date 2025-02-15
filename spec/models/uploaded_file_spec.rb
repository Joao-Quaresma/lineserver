require "rails_helper"

RSpec.describe UploadedFile, type: :model do
  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:size) }
    it { should validate_numericality_of(:size).is_greater_than(0) }
    it { should validate_presence_of(:line_count) }
    it { should validate_numericality_of(:line_count).is_greater_than_or_equal_to(0) }
  end
end

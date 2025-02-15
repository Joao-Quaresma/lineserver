FactoryBot.define do
  factory :uploaded_file do
    name { "testfile.txt" }
    size { 123 }
    line_count { 10 }
  end
end

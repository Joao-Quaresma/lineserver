class CreateUploadedFiles < ActiveRecord::Migration[8.0]
  def change
    create_table :uploaded_files, id: :uuid do |t|
      t.string :name, null: false
      t.integer :size, null: false
      t.integer :line_count, null: false

      t.timestamps
    end
  end
end

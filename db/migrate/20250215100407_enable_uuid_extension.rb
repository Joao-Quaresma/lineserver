class EnableUuidExtension < ActiveRecord::Migration[8.0]
  def change
    enable_extension 'pgcrypto' # Enables UUID generation
  end
end

class AddChecksumToReleases < ActiveRecord::Migration[6.1]
  def change
    add_column :releases, :checksum, :string, null: true
  end
end

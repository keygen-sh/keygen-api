class AddStatusToReleases < ActiveRecord::Migration[7.0]
  def change
    add_column :releases, :status, :string, null: true

    add_index :releases, :status
  end
end

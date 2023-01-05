class AddEnvironmentToReleases < ActiveRecord::Migration[7.0]
  def change
    add_column :releases, :environment_id, :uuid, null: true

    add_index :releases, :environment_id
  end
end

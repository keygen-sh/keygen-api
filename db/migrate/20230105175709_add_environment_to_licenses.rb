class AddEnvironmentToLicenses < ActiveRecord::Migration[7.0]
  def change
    add_column :licenses, :environment_id, :uuid, null: true

    add_index :licenses, :environment_id
  end
end

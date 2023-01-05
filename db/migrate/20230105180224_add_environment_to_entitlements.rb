class AddEnvironmentToEntitlements < ActiveRecord::Migration[7.0]
  def change
    add_column :entitlements, :environment_id, :uuid, null: true

    add_index :entitlements, :environment_id
  end
end

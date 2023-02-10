class AddEnvironmentToPolicyEntitlements < ActiveRecord::Migration[7.0]
  def change
    add_column :policy_entitlements, :environment_id, :uuid, null: true

    add_index :policy_entitlements, :environment_id
  end
end

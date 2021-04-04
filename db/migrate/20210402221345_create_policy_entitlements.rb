class CreatePolicyEntitlements < ActiveRecord::Migration[6.1]
  def change
    create_table :policy_entitlements, id: :uuid, default: -> { "uuid_generate_v4()" } do |t|
      t.uuid :account_id, null: false
      t.uuid :policy_id, null: false
      t.uuid :entitlement_id, null: false
      t.timestamps
    end

    add_index :policy_entitlements, [:account_id, :policy_id, :entitlement_id], name: :policy_entitlements_acct_lic_ent_ids_idx, unique: true
    add_index :policy_entitlements, :policy_id
    add_index :policy_entitlements, :entitlement_id
  end
end

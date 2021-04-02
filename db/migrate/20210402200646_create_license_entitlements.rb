class CreateLicenseEntitlements < ActiveRecord::Migration[6.1]
  def change
    create_table :license_entitlements, id: :uuid, default: -> { "uuid_generate_v4()" } do |t|
      t.uuid :account_id, null: false
      t.uuid :license_id, null: false
      t.uuid :entitlement_id, null: false
      t.timestamps
    end

    add_index :license_entitlements, [:account_id, :license_id, :entitlement_id], name: :license_entitlements_acct_lic_ent_ids_idx, unique: true
    add_index :license_entitlements, :license_id
    add_index :license_entitlements, :entitlement_id
  end
end

class CreateReleaseEntitlementConstraints < ActiveRecord::Migration[6.1]
  def change
    create_table :release_entitlement_constraints, id: :uuid, default: -> { "uuid_generate_v4()" } do |t|
      t.uuid :account_id, null: false
      t.uuid :release_id, null: false
      t.uuid :entitlement_id, null: false

      t.timestamps

      t.index %i[account_id release_id entitlement_id], name: :release_entls_acct_rel_ent_ids_idx, unique: true
      t.index %i[account_id created_at], name: :release_entls_acct_created_idx, order: { created_at: :desc }
      t.index %i[release_id]
      t.index %i[entitlement_id]
    end
  end
end

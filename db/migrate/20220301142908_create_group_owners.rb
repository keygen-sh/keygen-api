class CreateGroupOwners < ActiveRecord::Migration[6.1]
  def change
    create_table :group_owners, id: :uuid, default: -> { 'uuid_generate_v4()' } do |t|
      t.uuid :account_id, null: false
      t.uuid :group_id, null: false
      t.string :owner_type, null: false
      t.uuid :owner_id, null: false

      t.timestamps

      t.index %i[account_id]
      t.index %i[group_id]

      # Owners must be unique per-group
      t.index %i[group_id owner_type owner_id], unique: true
    end
  end
end

class CreateGroupOwners < ActiveRecord::Migration[6.1]
  def change
    create_table :group_owners, id: :uuid, default: -> { 'uuid_generate_v4()' } do |t|
      t.uuid :account_id, null: false
      t.uuid :group_id, null: false
      t.uuid :user_id, null: false

      t.timestamps

      t.index %i[account_id]
      t.index %i[group_id]
      t.index %i[user_id]

      # Owners must be unique per-group
      t.index %i[group_id user_id], unique: true
    end
  end
end

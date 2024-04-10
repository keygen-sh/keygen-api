class CreateLicenseUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :license_users, id: :uuid, default: -> { 'uuid_generate_v4()' }, if_not_exists: true do |t|
      t.uuid :account_id,     null: false
      t.uuid :environment_id, null: true
      t.uuid :license_id,     null: false
      t.uuid :user_id,        null: false

      t.timestamps

      t.index %i[account_id created_at], order: { created_at: :desc }
      t.index %i[environment_id]
      t.index %i[license_id user_id account_id], unique: true
      t.index %i[user_id]
    end
  end
end

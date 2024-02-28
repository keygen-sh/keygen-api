class CreateLicensesUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :licenses_users, id: :uuid, default: -> { 'uuid_generate_v4()' } do |t|
      t.uuid :license_id, null: false
      t.uuid :user_id,    null: false

      t.timestamps

      t.index %i[license_id user_id], unique: true
      t.index %i[user_id]
    end
  end
end

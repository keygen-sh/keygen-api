class CreateGroups < ActiveRecord::Migration[6.1]
  def change
    create_table :groups, id: :uuid, default: -> { 'uuid_generate_v4()' } do |t|
      t.uuid :account_id, null: false

      t.string :name
      t.integer :max_users
      t.integer :max_licenses
      t.integer :max_machines
      t.jsonb :metadata

      t.timestamps

      t.index %i[account_id]
    end
  end
end

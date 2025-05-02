class CreateAccountSettings < ActiveRecord::Migration[7.2]
  verbose!

  def change
    create_table :account_settings, id: :uuid, default: -> { 'uuid_generate_v4()' } do |t|
      t.uuid :account_id, null: false
      t.string :key, null: false
      t.jsonb :value, null: false
      t.timestamps

      t.index %i[account_id created_at], order: { created_at: :desc }
      t.index %i[account_id key], unique: true
    end
  end
end

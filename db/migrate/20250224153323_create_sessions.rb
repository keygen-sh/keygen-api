class CreateSessions < ActiveRecord::Migration[7.2]
  def change
    create_table :sessions, id: :uuid, default: -> { 'uuid_generate_v4()' } do |t|
      t.uuid :account_id,          null: false
      t.uuid :environment_id,      null: true
      t.uuid :token_id,            null: false
      t.string :bearer_type,       null: false
      t.uuid :bearer_id,           null: false

      t.datetime :last_used_at,    null: true
      t.datetime :expiry,          null: false
      t.string :ip,                null: false
      t.string :user_agent,        null: true

      t.timestamps

      t.index %i[account_id created_at], order: { created_at: :desc }
      t.index %i[environment_id]
      t.index %i[token_id]
      t.index %i[bearer_id bearer_type]
      t.index %i[created_at expiry last_used_at], order: { created_at: :asc }
    end
  end
end

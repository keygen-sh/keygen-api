class CreateMachineComponents < ActiveRecord::Migration[7.0]
  def change
    create_table :machine_components, id: :uuid, default: -> { 'uuid_generate_v4()' } do |t|
      t.uuid :account_id,        null: false
      t.uuid :machine_id,        null: false
      t.uuid :environment_id,    null: true

      t.string :fingerprint, null: false
      t.string :name,        null: false
      t.jsonb :metadata

      t.timestamps

      t.index %i[account_id created_at], order: { created_at: :desc }
      t.index %i[machine_id fingerprint], unique: true
      t.index %i[environment_id]
      t.index %i[fingerprint]
    end
  end
end

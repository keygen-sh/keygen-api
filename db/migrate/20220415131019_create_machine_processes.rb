class CreateMachineProcesses < ActiveRecord::Migration[7.0]
  def change
    create_table :machine_processes, id: :uuid, default: -> { 'uuid_generate_v4()' } do |t|
      t.uuid :account_id, null: false
      t.uuid :machine_id, null: false

      t.string   :pid,                      null: false
      t.datetime :last_heartbeat_at,        null: false
      t.datetime :last_death_event_sent_at, null: true
      t.jsonb    :metadata

      t.timestamps

      t.index :account_id
      t.index :machine_id
      t.index %{machine_id, md5(pid)}, unique: true
      t.index :last_heartbeat_at
    end
  end
end

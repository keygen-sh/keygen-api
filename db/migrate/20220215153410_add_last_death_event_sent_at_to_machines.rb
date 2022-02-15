class AddLastDeathEventSentAtToMachines < ActiveRecord::Migration[6.1]
  def change
    add_column :machines, :last_death_event_sent_at, :timestamp, null: true
  end
end

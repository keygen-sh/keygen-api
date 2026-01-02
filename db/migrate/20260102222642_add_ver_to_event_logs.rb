class AddVerToEventLogs < ActiveRecord::Migration[8.1]
  def change
    add_column :event_logs, :ver, :integer
  end
end

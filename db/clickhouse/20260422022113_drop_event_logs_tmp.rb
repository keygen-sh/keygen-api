class DropEventLogsTmp < ActiveRecord::Migration[8.1]
  verbose!

  def up
    drop_table :event_logs_tmp, if_exists: true
  end
end

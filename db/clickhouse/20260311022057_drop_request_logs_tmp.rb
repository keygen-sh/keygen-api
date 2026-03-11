class DropRequestLogsTmp < ActiveRecord::Migration[8.1]
  verbose!

  def up
    drop_table :request_logs_tmp
  end
end

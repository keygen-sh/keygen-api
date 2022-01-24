class RemoveNullableCreatedDateFromRequestLogs < ActiveRecord::Migration[6.1]
  def change
    change_column :request_logs, :created_date, :date, null: false
  end
end

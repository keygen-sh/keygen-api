class RemoveNullableCreatedDateFromRequestLogs < ActiveRecord::Migration[7.0]
  def change
    change_column_null :request_logs, :created_date, false
  end
end

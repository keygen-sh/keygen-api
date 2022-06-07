class RemoveNullableCreatedDateFromMetrics < ActiveRecord::Migration[7.0]
  def change
    change_column_null :metrics, :created_date, false
  end
end

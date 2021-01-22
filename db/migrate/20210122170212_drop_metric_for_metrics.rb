class DropMetricForMetrics < ActiveRecord::Migration[5.2]
  def change
    remove_column :metrics, :metric
  end
end

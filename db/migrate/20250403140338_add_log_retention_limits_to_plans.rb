class AddLogRetentionLimitsToPlans < ActiveRecord::Migration[7.2]
  verbose!

  def change
    add_column :plans, :request_log_retention_duration, :integer
    add_column :plans, :event_log_retention_duration,   :integer
  end
end

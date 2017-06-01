class RenameCheckInFieldsForPolicies < ActiveRecord::Migration[5.0]
  def change
    rename_column :policies, :check_in_interval, :check_in_interval_count
    rename_column :policies, :check_in_duration, :check_in_interval
  end
end

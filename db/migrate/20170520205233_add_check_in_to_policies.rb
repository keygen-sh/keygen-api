class AddCheckInToPolicies < ActiveRecord::Migration[5.0]
  def change
    add_column :policies, :check_in_duration, :string
    add_column :policies, :check_in_interval, :integer
    add_column :policies, :require_check_in, :boolean, default: false
  end
end

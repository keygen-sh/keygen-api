class ChangeMaxMachinesDefaultForPolicies < ActiveRecord::Migration[5.0]
  def change
    change_column_default :policies, :max_machines, nil
  end
end

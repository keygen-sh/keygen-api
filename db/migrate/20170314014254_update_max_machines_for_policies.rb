# frozen_string_literal: true

class UpdateMaxMachinesForPolicies < ActiveRecord::Migration[5.0]
  def change
    Policy.where(max_machines: nil).update_all max_machines: 1

    change_column_default :policies, :max_machines, 1
  end
end

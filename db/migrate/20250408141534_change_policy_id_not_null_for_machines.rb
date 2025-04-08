class ChangePolicyIdNotNullForMachines < ActiveRecord::Migration[7.2]
  verbose!

  def up
    change_column_null :machines, :policy_id, false
    remove_check_constraint :machines, name: 'machines_policy_id_not_null'
  end
end

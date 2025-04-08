class AddPolicyIdNotNullConstraintForMachines < ActiveRecord::Migration[7.2]
  verbose!

  def up
    add_check_constraint :machines, 'policy_id IS NOT NULL', name: 'machines_policy_id_not_null', validate: false
  end
end

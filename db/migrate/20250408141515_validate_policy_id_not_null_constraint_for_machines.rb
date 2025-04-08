class ValidatePolicyIdNotNullConstraintForMachines < ActiveRecord::Migration[7.2]
  verbose!

  def up
    validate_check_constraint :machines, name: 'machines_policy_id_not_null'
  end
end

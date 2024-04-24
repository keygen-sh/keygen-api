class ValidatePolicyIdNotNullConstraintForLicenses < ActiveRecord::Migration[7.1]
  verbose!

  def up
    validate_check_constraint :licenses, name: 'licenses_policy_id_not_null'
  end
end

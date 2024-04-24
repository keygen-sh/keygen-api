class AddPolicyIdNotNullConstraintForLicenses < ActiveRecord::Migration[7.1]
  verbose!

  def up
    add_check_constraint :licenses, 'policy_id IS NOT NULL', name: 'licenses_policy_id_not_null', validate: false
  end
end

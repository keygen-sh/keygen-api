class AddPolicyIdNotNullConstraintForLicenses < ActiveRecord::Migration[7.1]
  def up
    add_check_constraint :licenses, 'policy_id IS NOT NULL', name: 'licenses_policy_id_null', validate: false
  end
end

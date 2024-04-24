class ChangePolicyIdNotNullForLicenses < ActiveRecord::Migration[7.1]
  verbose!

  def up
    change_column_null :licenses, :policy_id, false
    remove_check_constraint :licenses, name: 'licenses_policy_id_not_null'
  end
end

class AddAccountIdNotNullConstraintForLicenses < ActiveRecord::Migration[7.1]
  def up
    add_check_constraint :licenses, 'account_id IS NOT NULL', name: 'licenses_account_id_null', validate: false
  end
end

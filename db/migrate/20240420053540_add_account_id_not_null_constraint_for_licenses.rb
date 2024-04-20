class AddAccountIdNotNullConstraintForLicenses < ActiveRecord::Migration[7.1]
  verbose!

  def up
    add_check_constraint :licenses, 'account_id IS NOT NULL', name: 'licenses_account_id_not_null', validate: false
  end
end

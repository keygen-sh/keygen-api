class ValidateAccountIdNotNullConstraintForRoles < ActiveRecord::Migration[7.2]
  verbose!

  def up
    validate_check_constraint :roles, name: 'roles_account_id_not_null'
  end
end

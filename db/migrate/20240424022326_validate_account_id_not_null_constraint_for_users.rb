class ValidateAccountIdNotNullConstraintForUsers < ActiveRecord::Migration[7.1]
  verbose!

  def up
    validate_check_constraint :users, name: 'users_account_id_not_null'
  end
end

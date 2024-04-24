class AddAccountIdNotNullConstraintForUsers < ActiveRecord::Migration[7.1]
  verbose!

  def up
    add_check_constraint :users, 'account_id IS NOT NULL', name: 'users_account_id_not_null', validate: false
  end
end

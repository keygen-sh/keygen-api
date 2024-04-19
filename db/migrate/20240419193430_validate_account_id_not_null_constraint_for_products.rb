class ValidateAccountIdNotNullConstraintForProducts < ActiveRecord::Migration[7.1]
  def up
    validate_check_constraint :products, name: 'products_account_id_null'

    change_column_null :products, :account_id, false
    remove_check_constraint :products, name: 'products_account_id_null'
  end
end

class ValidateAccountIdNotNullConstraintForProducts < ActiveRecord::Migration[7.1]
  verbose!

  def up
    validate_check_constraint :products, name: 'products_account_id_not_null'
  end
end

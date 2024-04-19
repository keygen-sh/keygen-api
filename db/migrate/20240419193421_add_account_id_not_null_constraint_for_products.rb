class AddAccountIdNotNullConstraintForProducts < ActiveRecord::Migration[7.1]
  def up
    add_check_constraint :products, 'account_id IS NOT NULL', name: 'products_account_id_null', validate: false
  end
end

class AddAccountIdNotNullConstraintForProducts < ActiveRecord::Migration[7.1]
  verbose!

  def up
    add_check_constraint :products, 'account_id IS NOT NULL', name: 'products_account_id_not_null', validate: false
  end
end

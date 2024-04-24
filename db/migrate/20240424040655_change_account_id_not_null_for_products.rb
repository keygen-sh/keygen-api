class ChangeAccountIdNotNullForProducts < ActiveRecord::Migration[7.1]
  verbose!

  def up
    change_column_null :products, :account_id, false
    remove_check_constraint :products, name: 'products_account_id_not_null'
  end
end

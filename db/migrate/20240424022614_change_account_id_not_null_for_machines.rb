class ChangeAccountIdNotNullForMachines < ActiveRecord::Migration[7.1]
  verbose!

  def up
    change_column_null :machines, :account_id, false
    remove_check_constraint :machines, name: 'machines_account_id_not_null'
  end
end

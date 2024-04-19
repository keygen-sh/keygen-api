class AddAccountIdNotNullConstraintForMachines < ActiveRecord::Migration[7.1]
  def up
    add_check_constraint :machines, 'account_id IS NOT NULL', name: 'machines_account_id_null', validate: false
  end
end

class AddAccountIdNotNullConstraintForMachines < ActiveRecord::Migration[7.1]
  verbose!

  def up
    add_check_constraint :machines, 'account_id IS NOT NULL', name: 'machines_account_id_not_null', validate: false
  end
end

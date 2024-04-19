class AddAccountIdNotNullConstraintForBillings < ActiveRecord::Migration[7.1]
  def up
    add_check_constraint :billings, 'account_id IS NOT NULL', name: 'billings_account_id_null', validate: false
  end
end

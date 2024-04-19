class AddAccountIdNotNullConstraintForKeys < ActiveRecord::Migration[7.1]
  def up
    add_check_constraint :keys, 'account_id IS NOT NULL', name: 'keys_account_id_null', validate: false
  end
end

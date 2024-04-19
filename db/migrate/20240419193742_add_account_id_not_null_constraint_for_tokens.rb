class AddAccountIdNotNullConstraintForTokens < ActiveRecord::Migration[7.1]
  def up
    add_check_constraint :tokens, 'account_id IS NOT NULL', name: 'tokens_account_id_null', validate: false
  end
end

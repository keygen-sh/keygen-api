class ValidateAccountIdNotNullConstraintForTokens < ActiveRecord::Migration[7.1]
  def up
    validate_check_constraint :tokens, name: 'tokens_account_id_null'

    change_column_null :tokens, :account_id, false
    remove_check_constraint :tokens, name: 'tokens_account_id_null'
  end
end

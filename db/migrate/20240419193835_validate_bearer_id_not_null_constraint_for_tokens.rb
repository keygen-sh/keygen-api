class ValidateBearerIdNotNullConstraintForTokens < ActiveRecord::Migration[7.1]
  def up
    validate_check_constraint :tokens, name: 'tokens_bearer_id_null'

    change_column_null :tokens, :bearer_id, false
    remove_check_constraint :tokens, name: 'tokens_bearer_id_null'
  end
end

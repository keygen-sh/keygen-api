class ValidateBearerTypeNotNullConstraintForTokens < ActiveRecord::Migration[7.1]
  def up
    validate_check_constraint :tokens, name: 'tokens_bearer_type_null'

    change_column_null :tokens, :bearer_type, false
    remove_check_constraint :tokens, name: 'tokens_bearer_type_null'
  end
end

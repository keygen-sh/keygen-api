class AddBearerTypeNotNullConstraintForTokens < ActiveRecord::Migration[7.1]
  def up
    add_check_constraint :tokens, 'bearer_type IS NOT NULL', name: 'tokens_bearer_type_null', validate: false
  end
end

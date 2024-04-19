class AddBearerIdNotNullConstraintForTokens < ActiveRecord::Migration[7.1]
  def up
    add_check_constraint :tokens, 'bearer_id IS NOT NULL', name: 'tokens_bearer_id_null', validate: false
  end
end

class ValidatePolicyIdNotNullConstraintForKeys < ActiveRecord::Migration[7.1]
  def up
    validate_check_constraint :keys, name: 'keys_policy_id_null'

    change_column_null :keys, :policy_id, false
    remove_check_constraint :keys, name: 'keys_policy_id_null'
  end
end

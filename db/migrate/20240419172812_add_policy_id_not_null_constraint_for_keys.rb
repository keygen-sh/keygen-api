class AddPolicyIdNotNullConstraintForKeys < ActiveRecord::Migration[7.1]
  def up
    add_check_constraint :keys, 'policy_id IS NOT NULL', name: 'keys_policy_id_null', validate: false
  end
end

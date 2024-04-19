class ValidateResourceIdNotNullConstraintForRoles < ActiveRecord::Migration[7.1]
  def up
    validate_check_constraint :roles, name: 'roles_resource_id_null'

    change_column_null :roles, :resource_id, false
    remove_check_constraint :roles, name: 'roles_resource_id_null'
  end
end

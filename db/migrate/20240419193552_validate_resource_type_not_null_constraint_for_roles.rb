class ValidateResourceTypeNotNullConstraintForRoles < ActiveRecord::Migration[7.1]
  def up
    validate_check_constraint :roles, name: 'roles_resource_type_null'

    change_column_null :roles, :resource_type, false
    remove_check_constraint :roles, name: 'roles_resource_type_null'
  end
end

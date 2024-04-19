class AddResourceTypeNotNullConstraintForRoles < ActiveRecord::Migration[7.1]
  def up
    add_check_constraint :roles, 'resource_type IS NOT NULL', name: 'roles_resource_type_null', validate: false
  end
end

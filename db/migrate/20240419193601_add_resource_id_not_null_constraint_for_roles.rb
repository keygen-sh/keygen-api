class AddResourceIdNotNullConstraintForRoles < ActiveRecord::Migration[7.1]
  def up
    add_check_constraint :roles, 'resource_id IS NOT NULL', name: 'roles_resource_id_null', validate: false
  end
end

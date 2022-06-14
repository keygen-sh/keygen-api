class AddResourceNameIndexToRoles < ActiveRecord::Migration[7.0]
  def change
    add_index :roles, %i[resource_type resource_id name]
  end
end

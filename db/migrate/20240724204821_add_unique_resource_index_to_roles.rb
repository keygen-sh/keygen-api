class AddUniqueResourceIndexToRoles < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!
  verbose!

  def change
    add_index :roles, %i[resource_id resource_type], unique: true, algorithm: :concurrently, if_not_exists: true
  end
end

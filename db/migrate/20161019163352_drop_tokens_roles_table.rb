class DropTokensRolesTable < ActiveRecord::Migration[5.0]
  def up
    drop_table :tokens_roles
  end
end

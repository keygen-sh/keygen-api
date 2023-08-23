class AddRequireComponentsScopeToPolicies < ActiveRecord::Migration[7.0]
  def change
    add_column :policies, :require_components_scope, :boolean, default: false, null: false
  end
end

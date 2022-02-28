class AddRequireUserScopeToPolicies < ActiveRecord::Migration[6.1]
  def change
    add_column :policies, :require_user_scope, :boolean, default: false, null: false
  end
end

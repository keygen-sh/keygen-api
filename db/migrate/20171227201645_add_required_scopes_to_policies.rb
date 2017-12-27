class AddRequiredScopesToPolicies < ActiveRecord::Migration[5.0]
  def change
    add_column :policies, :require_product_scope, :boolean, default: false
    add_column :policies, :require_policy_scope, :boolean, default: false
    add_column :policies, :require_machine_scope, :boolean, default: false
    add_column :policies, :require_fingerprint_scope, :boolean, default: false
  end
end

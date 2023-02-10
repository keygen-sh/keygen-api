class AddEnvironmentToReleaseEntitlementConstraints < ActiveRecord::Migration[7.0]
  def change
    add_column :release_entitlement_constraints, :environment_id, :uuid, null: true

    add_index :release_entitlement_constraints, :environment_id
  end
end

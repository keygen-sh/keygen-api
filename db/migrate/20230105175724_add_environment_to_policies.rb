class AddEnvironmentToPolicies < ActiveRecord::Migration[7.0]
  def change
    add_column :policies, :environment_id, :uuid, null: true

    add_index :policies, :environment_id
  end
end

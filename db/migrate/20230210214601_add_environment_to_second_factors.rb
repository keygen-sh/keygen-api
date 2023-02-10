class AddEnvironmentToSecondFactors < ActiveRecord::Migration[7.0]
  def change
    add_column :second_factors, :environment_id, :uuid, null: true

    add_index :second_factors, :environment_id
  end
end

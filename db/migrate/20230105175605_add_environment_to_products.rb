class AddEnvironmentToProducts < ActiveRecord::Migration[7.0]
  def change
    add_column :products, :environment_id, :uuid, null: true

    add_index :products, :environment_id
  end
end

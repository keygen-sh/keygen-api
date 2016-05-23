class CreatePolicies < ActiveRecord::Migration[5.0]
  def change
    create_table :policies do |t|
      t.string :name
      t.integer :price
      t.integer :duration
      t.boolean :strict
      t.boolean :recurring
      t.boolean :floating
      t.boolean :use_pool

      t.timestamps
    end
  end
end

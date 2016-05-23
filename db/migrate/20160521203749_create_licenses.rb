class CreateLicenses < ActiveRecord::Migration[5.0]
  def change
    create_table :licenses do |t|
      t.string :key
      t.datetime :expiry
      t.integer :activations
      t.references :user

      t.timestamps
    end
  end
end

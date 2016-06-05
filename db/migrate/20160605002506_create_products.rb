class CreateProducts < ActiveRecord::Migration[5.0]
  def change
    create_table :products do |t|
      t.string  :name
      t.string  :platforms
      t.integer :account_id

      t.timestamps
    end
  end
end

class AddSlugToProducts < ActiveRecord::Migration[7.0]
  def change
    add_column :products, :slug, :string, null: true

    add_index :products, %i[account_id slug], unique: true
  end
end

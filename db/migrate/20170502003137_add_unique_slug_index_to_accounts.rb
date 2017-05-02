class AddUniqueSlugIndexToAccounts < ActiveRecord::Migration[5.0]
  def change
    add_index :accounts, [:created_at, :slug], unique: true
    add_index :accounts, :slug, unique: true
  end
end

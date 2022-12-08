class AddUniqueIndexToKeyForKeys < ActiveRecord::Migration[7.0]
  def change
    add_index :keys, %i[account_id key], unique: true
  end
end

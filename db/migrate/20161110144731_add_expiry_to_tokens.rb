class AddExpiryToTokens < ActiveRecord::Migration[5.0]
  def change
    add_column :tokens, :expiry, :datetime
  end
end

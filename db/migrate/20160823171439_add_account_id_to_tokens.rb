class AddAccountIdToTokens < ActiveRecord::Migration[5.0]
  def change
    add_column :tokens, :account_id, :integer
  end
end

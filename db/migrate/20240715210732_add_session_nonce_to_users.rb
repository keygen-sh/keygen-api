class AddSessionNonceToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :session_nonce, :integer, limit: 8
  end
end

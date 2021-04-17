class UpdateDigestIndexForTokens < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    remove_index :tokens, [:digest, :created_at, :account_id]

    add_index :tokens, :digest, unique: true, algorithm: :concurrently
  end
end

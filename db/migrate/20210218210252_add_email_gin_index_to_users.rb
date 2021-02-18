class AddEmailGinIndexToUsers < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    remove_index :users, name: :users_tsv_email_idx

    add_index :users, :email, algorithm: :concurrently, using: :gin
  end
end

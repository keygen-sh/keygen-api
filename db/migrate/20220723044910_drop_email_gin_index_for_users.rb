class DropEmailGinIndexForUsers < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    remove_index :users, :email, name: :index_users_on_email, algorithm: :concurrently, using: :gin
  end
end

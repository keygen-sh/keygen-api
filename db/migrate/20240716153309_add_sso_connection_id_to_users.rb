class AddSsoConnectionIdToUsers < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_column :users, :sso_connection_id, :string, null: true
  end
end

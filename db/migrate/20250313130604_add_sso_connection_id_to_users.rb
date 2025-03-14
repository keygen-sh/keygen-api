class AddSsoConnectionIdToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :sso_connection_id, :string, null: true
  end
end

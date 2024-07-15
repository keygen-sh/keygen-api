class AddSsoIdpIdToUsers < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_column :users, :sso_idp_id, :string, null: true
    add_index :users, %i[account_id sso_idp_id], unique: true, algorithm: :concurrently
  end
end

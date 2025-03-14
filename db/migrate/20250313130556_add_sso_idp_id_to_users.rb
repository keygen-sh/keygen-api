class AddSsoIdpIdToUsers < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    add_column :users, :sso_idp_id, :string, null: true
  end
end

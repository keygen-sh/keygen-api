# frozen_string_literal: true

class RemoveAuthTokenFromUsers < ActiveRecord::Migration[5.0]
  def change
    remove_column :users, :auth_token, :string
    remove_column :users, :reset_auth_token, :string
  end
end

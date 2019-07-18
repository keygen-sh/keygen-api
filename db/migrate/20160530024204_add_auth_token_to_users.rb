# frozen_string_literal: true

class AddAuthTokenToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :auth_token, :string
    add_column :users, :reset_auth_token, :string
  end
end

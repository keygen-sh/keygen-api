# frozen_string_literal: true

class DropProductsUsersTable < ActiveRecord::Migration[5.0]
  def up
    drop_table :products_users
  end
end

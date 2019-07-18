# frozen_string_literal: true

class RemoveEmailFromAccounts < ActiveRecord::Migration[5.0]
  def change
    remove_column :accounts, :email, :string
  end
end

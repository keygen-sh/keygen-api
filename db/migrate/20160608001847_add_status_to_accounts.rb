# frozen_string_literal: true

class AddStatusToAccounts < ActiveRecord::Migration[5.0]
  def change
    add_column :accounts, :status, :string, default: "active"
  end
end

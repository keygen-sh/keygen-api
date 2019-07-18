# frozen_string_literal: true

class RemoveStatusFromAccounts < ActiveRecord::Migration[5.0]
  def change
    remove_column :accounts, :status, :string
  end
end

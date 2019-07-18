# frozen_string_literal: true

class AddBillingToAccounts < ActiveRecord::Migration[5.0]
  def change
    add_column :accounts, :billing_id, :integer
  end
end

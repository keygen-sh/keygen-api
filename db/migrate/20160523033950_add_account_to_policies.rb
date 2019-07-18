# frozen_string_literal: true

class AddAccountToPolicies < ActiveRecord::Migration[5.0]
  def change
    add_column :policies, :account_id, :integer
  end
end

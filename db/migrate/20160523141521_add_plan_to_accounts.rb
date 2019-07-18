# frozen_string_literal: true

class AddPlanToAccounts < ActiveRecord::Migration[5.0]
  def change
    add_column :accounts, :plan_id, :integer
  end
end

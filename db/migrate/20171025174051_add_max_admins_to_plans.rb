# frozen_string_literal: true

class AddMaxAdminsToPlans < ActiveRecord::Migration[5.0]
  def change
    add_column :plans, :max_admins, :integer
  end
end

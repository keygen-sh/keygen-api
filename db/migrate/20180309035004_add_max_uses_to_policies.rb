# frozen_string_literal: true

class AddMaxUsesToPolicies < ActiveRecord::Migration[5.0]
  def change
    add_column :policies, :max_uses, :integer
  end
end

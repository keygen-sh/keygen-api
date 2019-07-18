# frozen_string_literal: true

class RemoveAttributesFromPolicies < ActiveRecord::Migration[5.0]
  def change
    remove_column :policies, :price, :integer
    remove_column :policies, :recurring, :boolean
  end
end

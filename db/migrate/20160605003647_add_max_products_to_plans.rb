# frozen_string_literal: true

class AddMaxProductsToPlans < ActiveRecord::Migration[5.0]
  def change
    add_column :plans, :max_products, :integer
  end
end

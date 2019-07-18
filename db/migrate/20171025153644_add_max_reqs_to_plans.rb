# frozen_string_literal: true

class AddMaxReqsToPlans < ActiveRecord::Migration[5.0]
  def change
    add_column :plans, :max_reqs, :integer
  end
end

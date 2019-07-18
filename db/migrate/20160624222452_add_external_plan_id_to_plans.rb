# frozen_string_literal: true

class AddExternalPlanIdToPlans < ActiveRecord::Migration[5.0]
  def change
    add_column :plans, :external_plan_id, :string
  end
end

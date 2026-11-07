# frozen_string_literal: true

class AddDurationStrategyToPolicies < ActiveRecord::Migration[8.1]
  def change
    # No backfill: nil preserves calendar arithmetic for existing policies.
    add_column :policies, :duration_strategy, :string
  end
end

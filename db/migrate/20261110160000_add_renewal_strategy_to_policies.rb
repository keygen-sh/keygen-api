# frozen_string_literal: true

class AddRenewalStrategyToPolicies < ActiveRecord::Migration[8.1]
  verbose!

  def change
    add_column :policies, :renewal_strategy, :string, null: true, if_not_exists: true
  end
end

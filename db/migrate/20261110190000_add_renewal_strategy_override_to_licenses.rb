# frozen_string_literal: true

class AddRenewalStrategyOverrideToLicenses < ActiveRecord::Migration[8.1]
  verbose!

  def change
    add_column :licenses, :renewal_strategy_override, :string, null: true, if_not_exists: true
  end
end

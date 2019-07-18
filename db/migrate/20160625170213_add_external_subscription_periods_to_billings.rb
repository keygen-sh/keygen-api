# frozen_string_literal: true

class AddExternalSubscriptionPeriodsToBillings < ActiveRecord::Migration[5.0]
  def change
    add_column :billings, :external_subscription_period_start, :datetime
    add_column :billings, :external_subscription_period_end, :datetime
  end
end

# frozen_string_literal: true

class RenameExternalStripeColumns < ActiveRecord::Migration[5.0]
  def change
    rename_column :billings, :customer_id, :account_id
    remove_column :billings, :customer_type

    rename_column :billings, :external_customer_id, :customer_id
    rename_column :billings, :external_subscription_status, :subscription_status
    rename_column :billings, :external_subscription_id, :subscription_id
    rename_column :billings, :external_subscription_period_start, :subscription_period_start
    rename_column :billings, :external_subscription_period_end, :subscription_period_end

    rename_column :plans, :external_plan_id, :plan_id
  end
end

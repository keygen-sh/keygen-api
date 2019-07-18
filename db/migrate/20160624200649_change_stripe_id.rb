# frozen_string_literal: true

class ChangeStripeId < ActiveRecord::Migration[5.0]
  def change
    rename_column :billings, :stripe_id, :external_customer_id
  end
end

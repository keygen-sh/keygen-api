# frozen_string_literal: true

class AddCustomerToBillings < ActiveRecord::Migration[5.0]
  def change
    add_column :billings, :customer_id, :integer
    add_column :billings, :customer_type, :string
  end
end

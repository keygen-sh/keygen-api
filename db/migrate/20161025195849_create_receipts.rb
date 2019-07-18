# frozen_string_literal: true

class CreateReceipts < ActiveRecord::Migration[5.0]
  def change
    create_table :receipts do |t|
      t.integer :billing_id
      t.string :invoice_id
      t.integer :amount
      t.boolean :paid

      t.timestamps
    end
  end
end

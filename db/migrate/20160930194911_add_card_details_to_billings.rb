class AddCardDetailsToBillings < ActiveRecord::Migration[5.0]
  def change
    add_column :billings, :card_expiry, :timestamp
    add_column :billings, :card_brand, :string
    add_column :billings, :card_last4, :string
  end
end

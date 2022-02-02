class AddCardAddedAtToBillings < ActiveRecord::Migration[6.1]
  def change
    add_column :billings, :card_added_at, :datetime
  end
end

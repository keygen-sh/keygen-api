class AddExternalSubscriptionIdToBillings < ActiveRecord::Migration[5.0]
  def change
    add_column :billings, :external_subscription_id, :string
  end
end

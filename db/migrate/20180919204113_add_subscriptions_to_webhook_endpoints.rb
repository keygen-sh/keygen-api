class AddSubscriptionsToWebhookEndpoints < ActiveRecord::Migration[5.0]
  def change
    add_column :webhook_endpoints, :subscriptions, :jsonb, default: ['*']
  end
end

class AddProductToWebhookEndpoints < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    add_column :webhook_endpoints, :product_id, :uuid, null: true, if_not_exists: true

    add_index :webhook_endpoints, :product_id, algorithm: :concurrently, if_not_exists: true
  end
end

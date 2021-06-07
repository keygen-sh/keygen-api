class AddSignatureAlgorithmToWebhookEndpoints < ActiveRecord::Migration[6.1]
  def change
    add_column :webhook_endpoints, :signature_algorithm, :string, default: 'ed25519'
  end
end

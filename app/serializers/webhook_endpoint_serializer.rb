class WebhookEndpointSerializer < BaseSerializer
  type :webhook_endpoints

  attributes [
    :url,
    :created,
    :updated
  ]

  belongs_to :account
end

# == Schema Information
#
# Table name: webhook_endpoints
#
#  id         :integer          not null, primary key
#  account_id :integer
#  url        :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_webhook_endpoints_on_account_id  (account_id)
#

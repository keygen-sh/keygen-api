class WebhookEndpointSerializer < BaseSerializer
  type :webhook_endpoints

  attributes :url,
             :created,
             :updated
end

# == Schema Information
#
# Table name: webhook_endpoints
#
#  url        :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  deleted_at :datetime
#  id         :uuid             not null, primary key
#  account_id :uuid
#
# Indexes
#
#  index_webhook_endpoints_on_account_id  (account_id)
#  index_webhook_endpoints_on_created_at  (created_at)
#  index_webhook_endpoints_on_deleted_at  (deleted_at)
#  index_webhook_endpoints_on_id          (id)
#

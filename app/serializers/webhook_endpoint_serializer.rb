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
#  id         :integer          not null, primary key
#  account_id :integer
#  url        :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  deleted_at :datetime
#
# Indexes
#
#  index_webhook_endpoints_on_account_id_and_id  (account_id,id)
#  index_webhook_endpoints_on_deleted_at         (deleted_at)
#

class WebhookEndpoint < ApplicationRecord
  include Limitable
  include Pageable

  belongs_to :account

  validates :account, presence: { message: "must exist" }
  validates :url, url: { protocols: %w[https] }, presence: true
end

# == Schema Information
#
# Table name: webhook_endpoints
#
#  id         :uuid             not null, primary key
#  url        :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :uuid
#
# Indexes
#
#  index_webhook_endpoints_on_created_at_and_account_id  (created_at,account_id)
#  index_webhook_endpoints_on_created_at_and_id          (created_at,id) UNIQUE
#  index_webhook_endpoints_on_id                         (id) UNIQUE
#

class WebhookEndpoint < ApplicationRecord
  include Limitable
  include Pageable

  belongs_to :account

  validates :account, presence: { message: "must exist" }
  validates :url, url: true, presence: true
end

# == Schema Information
#
# Table name: webhook_endpoints
#
#  id         :uuid             not null, primary key
#  url        :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  deleted_at :datetime
#  account_id :uuid
#
# Indexes
#
#  index_webhook_endpoints_on_account_id  (account_id)
#  index_webhook_endpoints_on_created_at  (created_at)
#

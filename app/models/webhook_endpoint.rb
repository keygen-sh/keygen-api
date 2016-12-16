class WebhookEndpoint < ApplicationRecord
  include Limitable
  include Pageable

  acts_as_paranoid

  belongs_to :account

  validates :account, presence: { message: "must exist" }
  validates :url, url: true, presence: true
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

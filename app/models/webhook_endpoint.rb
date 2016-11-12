class WebhookEndpoint < ApplicationRecord
  include Paginatable
  include Limitable

  belongs_to :account

  validates :account, presence: { message: "must exist" }
  validates :url, url: true, presence: true
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

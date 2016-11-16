class WebhookEndpoint < ApplicationRecord
  include Paginatable
  include Limitable

  acts_as_paranoid

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
#  deleted_at :datetime
#
# Indexes
#
#  index_webhook_endpoints_on_account_id  (account_id)
#  index_webhook_endpoints_on_deleted_at  (deleted_at)
#

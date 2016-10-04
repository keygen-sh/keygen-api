require "uri"

class WebhookEndpoint < ApplicationRecord
  belongs_to :account

  validates :account, presence: { message: "must exist" }
  validates :url, presence: true, format: URI::regexp(%w[http https])

  scope :page, -> (page = {}) { paginate(page[:number]).per page[:size] }
end

require "uri"

class WebhookEndpoint < ApplicationRecord
  include Paginatable

  belongs_to :account

  validates :account, presence: { message: "must exist" }
  validates :url, presence: true, format: URI::regexp(%w[http https])
end

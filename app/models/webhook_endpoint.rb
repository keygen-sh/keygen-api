require "uri"

class WebhookEndpoint < ApplicationRecord
  include Paginatable

  belongs_to :account

  validates :account, presence: { message: "must exist" }
  validates :url, url: true, presence: true
end

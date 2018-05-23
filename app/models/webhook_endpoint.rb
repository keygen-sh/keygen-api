class WebhookEndpoint < ApplicationRecord
  include Limitable
  include Pageable

  belongs_to :account

  validates :account, presence: { message: "must exist" }
  validates :url, url: { protocols: %w[https] }, presence: true
end

require "uri"

class WebhookEvent < ApplicationRecord
  include Paginatable

  belongs_to :account

  validates :account, presence: { message: "must exist" }
  validates :endpoint, presence: true, format: URI::regexp(%w[http https])
  validates :jid, presence: true, uniqueness: true
end

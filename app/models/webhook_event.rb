require "uri"

class WebhookEvent < ApplicationRecord
  belongs_to :account

  validates :account, presence: { message: "must exist" }
  validates :endpoint, presence: true, format: URI::regexp(%w[http https])
  validates :jid, presence: true, uniqueness: true

  scope :page, -> (page = {}) { paginate(page[:number]).per page[:size] }
end

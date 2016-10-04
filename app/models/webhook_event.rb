require "uri"

class WebhookEvent < ApplicationRecord
  belongs_to :account

  validates :account, presence: { message: "must exist" }
  validates :jid, presence: true, uniqueness: true

  scope :page, -> (page = {}) { paginate(page[:number]).per page[:size] }
end

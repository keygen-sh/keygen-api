class WebhookEvent < ApplicationRecord
  include Paginatable

  belongs_to :account

  validates :account, presence: { message: "must exist" }
  validates :endpoint, url: true, presence: true
  validates :jid, presence: true, uniqueness: true
end

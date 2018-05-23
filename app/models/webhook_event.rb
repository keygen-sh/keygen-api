class WebhookEvent < ApplicationRecord
  include Idempotentable
  include Limitable
  include Pageable

  belongs_to :account

  validates :account, presence: { message: "must exist" }
  validates :endpoint, url: true, presence: true

  scope :events, -> (*events) { where event: events }

  def status
    Sidekiq::Status.status(jid) || :unavailable rescue :queued
  end
end

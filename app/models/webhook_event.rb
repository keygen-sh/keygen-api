# frozen_string_literal: true

class WebhookEvent < ApplicationRecord
  include Idempotentable
  include Limitable
  include Pageable

  belongs_to :account

  validates :account, presence: { message: "must exist" }
  validates :endpoint, url: true, presence: true

  scope :events, -> (*events) { where event: events }

  def status
    return :unavailable if updated_at < 3.days.ago

    Sidekiq::Status.status(jid) rescue :queued
  end
end

# frozen_string_literal: true

class WebhookEvent < ApplicationRecord
  include Idempotentable
  include Limitable
  include Pageable

  belongs_to :account
  belongs_to :event_type

  validates :account, presence: { message: "must exist" }
  validates :endpoint, url: true, presence: true

  scope :events, -> (*events) { joins(:event_type).where(event_types: { event: events }) }

  def status
    return :queued if updated_at.nil?
    return :unavailable if updated_at < 3.days.ago

    Sidekiq::Status.status(jid) rescue :queued
  end
end

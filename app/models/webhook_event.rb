# frozen_string_literal: true

class WebhookEvent < ApplicationRecord
  include Idempotentable
  include Limitable
  include Pageable

  belongs_to :account
  belongs_to :event_type

  validates :account, presence: { message: "must exist" }
  validates :endpoint, url: true, presence: true

  scope :events, -> (*events) { where(event_type_id: EventType.where(event: events).pluck(:id)) }

  def status
    return :queued if updated_at.nil?
    return :unavailable if updated_at < 3.days.ago

    Sidekiq::Status.status(jid) rescue :queued
  end
end

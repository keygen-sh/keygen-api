# frozen_string_literal: true

class WebhookEvent < ApplicationRecord
  include Idempotentable
  include Limitable
  include Pageable

  belongs_to :account
  belongs_to :event_type

  validates :account, presence: { message: "must exist" }
  validates :event_type, presence: { message: "must exist" }
  validates :endpoint, url: true, presence: true

  # NOTE(ezekg) A lot of the time, we don't need to load the payload
  #             or last response body, e.g. when listing events.
  scope :without_blobs, -> {
    select(self.attribute_names - %w[payload last_response_body])
  }

  scope :with_events, -> (*events) { where(event_type_id: EventType.where(event: events).pluck(:id)) }

  def status
    return :queued if updated_at.nil?
    return :unavailable if updated_at < 3.days.ago

    Sidekiq::Status.status(jid) rescue :queued
  end

  def deconstruct
    attributes.values
  end

  def deconstruct_keys(keys)
    attributes.symbolize_keys
  end
end

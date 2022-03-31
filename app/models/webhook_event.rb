# frozen_string_literal: true

class WebhookEvent < ApplicationRecord
  include Idempotentable
  include Limitable
  include Orderable
  include Pageable

  belongs_to :account
  belongs_to :event_type

  validates :endpoint, url: true, presence: true

  scope :with_events, -> (*events) { where(event_type_id: EventType.where(event: events).pluck(:id)) }

  # FIXME(ezekg) Products should only be able to read events that are
  #              associated with the given product
  scope :for_product, -> id { self }

  def deconstruct
    attributes.values
  end

  def deconstruct_keys(keys)
    attributes.symbolize_keys
  end
end

# frozen_string_literal: true

class WebhookEvent < ApplicationRecord
  include Environmental
  include Idempotentable
  include Limitable
  include Orderable
  include Pageable

  has_environment

  belongs_to :account
  belongs_to :event_type

  validates :endpoint, url: true, presence: true

  validates :api_version,
    allow_nil: true,
    inclusion: {
      message: 'unsupported version',
      in: RequestMigrations.supported_versions,
    }

  scope :with_events, -> (*events) { where(event_type_id: EventType.where(event: events).pluck(:id)) }

  # FIXME(ezekg) Products should only be able to read events that are
  #              associated with the given product
  scope :for_product, -> id { self }
end

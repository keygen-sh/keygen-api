# frozen_string_literal: true

class WebhookEvent < ApplicationRecord
  include Environmental
  include Accountable
  include Idempotentable
  include Limitable
  include Orderable
  include Pageable

  belongs_to :event_type
  belongs_to :webhook_endpoint, optional: true
  has_one :product,
    through: :webhook_endpoint

  has_environment
  has_account

  validates :endpoint, url: true, presence: true

  validates :api_version,
    allow_nil: true,
    inclusion: {
      message: 'unsupported version',
      in: RequestMigrations.supported_versions,
    }

  scope :with_events, -> (*events) { where(event_type_id: EventType.where(event: events).pluck(:id)) }

  scope :for_product, -> id {
    joins(:product).where(products: { id: })
  }
end

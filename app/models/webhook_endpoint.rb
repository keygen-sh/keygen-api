# frozen_string_literal: true

class WebhookEndpoint < ApplicationRecord
  include Limitable
  include Orderable
  include Pageable

  belongs_to :account

  before_create -> { self.api_version ||= account.api_version }
  before_save -> { self.subscriptions = subscriptions.uniq }

  validates :subscriptions, length: { minimum: 1, message: "must have at least 1 webhook event subscription" }
  validates :url, url: { protocols: %w[https] }, presence: true
  validates :signature_algorithm,
    inclusion: { in: %w[ed25519 rsa-pss-sha256 rsa-sha256], message: 'unsupported signature algorithm' },
    allow_nil: true

  validates :api_version,
    allow_nil: true,
    inclusion: {
      message: 'unsupported version',
      in: Versionist.supported_versions,
    }

  validate do
    next if
      subscriptions == %w[*]

    event_types = EventType.pluck(:event)

    if (subscriptions - event_types).any?
      errors.add :subscriptions, :not_allowed, message: "unsupported webhook event type for subscription"
    end
  end

  def subscribed?(event)
    !(subscriptions & ['*', event]).empty?
  end

  def disable!
    self.subscriptions = []

    save!(validate: false, touch: false)
  end
end

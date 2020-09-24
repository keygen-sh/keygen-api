# frozen_string_literal: true

class WebhookEndpoint < ApplicationRecord
  include Limitable
  include Pageable

  belongs_to :account

  before_save -> { self.subscriptions = subscriptions.uniq }

  validates :account, presence: { message: "must exist" }
  validates :subscriptions, length: { minimum: 1, message: "must have at least 1 webhook event subscription" }
  validates :url, url: { protocols: %w[https] }, presence: true

  validate do
    if (subscriptions - EventType::EVENT_TYPES).any?
      errors.add :subscriptions, :not_allowed, message: "unsupported webhook event type for subscription"
    end
  end

  def subscribed?(event)
    !(subscriptions & ['*', event]).empty?
  end
end

module Billable
  extend ActiveSupport::Concern

  included do
    after_commit :initialize_billing, on: :create

    Billing::AVAILABLE_EVENTS.each do |event|
      delegate "#{event}!", to: :billing, allow_nil: true
      delegate "#{event}", to: :billing, allow_nil: true
    end

    Billing::AVAILABLE_STATES.each do |state|
      delegate "#{state}?", to: :billing, allow_nil: true
      delegate "#{state}", to: :billing, allow_nil: true
    end

    def active?
       # The only time this could happen is if Stripe hasn't sent us a "customer.created" event yet
      return true if billing.nil?

      billing.active?
    end
  end

  def initialize_billing
    InitializeBillingWorker.perform_async id
  end
end

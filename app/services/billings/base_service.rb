# frozen_string_literal: true

require 'stripe'

module Billings
  Event         = ::Stripe::Event
  BillingPortal = ::Stripe::BillingPortal
  Subscription  = ::Stripe::Subscription
  Schedule      = ::Stripe::SubscriptionSchedule
  Customer      = ::Stripe::Customer
  Error         = ::Stripe::StripeError

  class BaseService < ::BaseService; end
end

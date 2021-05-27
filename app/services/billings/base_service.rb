# frozen_string_literal: true

require 'stripe'

module Billings
  Event         = ::Stripe::Event
  BillingPortal = ::Stripe::BillingPortal
  Subscription  = ::Stripe::Subscription
  Customer      = ::Stripe::Customer
  Error         = ::Stripe::StripeError

  class BaseService < ::BaseService; end
end

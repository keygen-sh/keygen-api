# frozen_string_literal: true

require 'stripe'

module Billings
  class BaseService < ::BaseService
    Event         = ::Stripe::Event
    BillingPortal = ::Stripe::BillingPortal
    Subscription  = ::Stripe::Subscription
    Customer      = ::Stripe::Customer
    Error         = ::Stripe::StripeError
  end
end

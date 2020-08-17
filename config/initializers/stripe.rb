# frozen_string_literal: true

Rails.configuration.stripe = {
  :publishable_key => ENV['PUBLISHABLE_KEY'],
  :secret_key      => ENV['SECRET_KEY']
}

Stripe.api_key = Rails.configuration.stripe[:secret_key]

# FIXME(ezekg) Add resource for billing portal since we're pretty behind on
#              our Stripe version. We should probably upgrade.
module Stripe
  module BillingPortal
    class Session < APIResource
      extend Stripe::APIOperations::Create

      def self.resource_url
        "/v1/billing_portal/sessions"
      end
    end
  end
end

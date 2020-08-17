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

module StripeMock
  module InstanceExtensions
    attr_reader :billing_portal_sessions

    def initialize
      @billing_portal_sessions = {}

      super
    end
  end

  module RequestHandlers
    module BillingPortal
      module Session
        def Session.included(klass)
          klass.add_handler 'post /v1/billing_portal/sessions', :new_session
        end

        def new_session(route, method_url, params, headers)
          params[:id] ||= new_id('bps')

          billing_portal_sessions[params[:id]] = Data.mock_billing_portal_session(params)
        end
     end
    end
  end

  module Data
    def self.mock_billing_portal_session(params = {})
      bps_id = params[:id] || "test_bps_default"
      {
        id: bps_id,
        object: "billing_portal.session",
        created: Time.current.to_i,
        customer: nil,
        livemode: false,
        return_url: "https://example.com/account",
        url: "https://billing.stripe.com/session/test_session_secret"
      }.merge(params)
    end
  end

  class Instance
    prepend InstanceExtensions

    include StripeMock::RequestHandlers::BillingPortal
    include StripeMock::RequestHandlers::BillingPortal::Session
  end
end
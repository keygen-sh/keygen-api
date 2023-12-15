# frozen_string_literal: true

require 'stripe_mock'

class StripeHelper
  attr_accessor :helper

  def initialize
    Stripe.api_key = "test"
  end

  class << self
    def start
      StripeMock.start
      instance.helper = StripeMock.create_test_helper
    end

    def stop
      StripeMock.stop
    end

    def method_missing(method, ...)
      if instance.respond_to?(method)
        instance.send(method, ...)
      else
        instance.helper.send(method, ...)
      end
    end

    def instance
      @instance ||= self.new
    end
  end
end

# frozen_string_literal: true

module Billings
  class DeleteSubscriptionService < BaseService

    def initialize(subscription:, at_period_end: true)
      @subscription = subscription
      @at_period_end = at_period_end
    end

    def execute
      c = Billings::BaseService::Subscription.retrieve subscription
      c.delete at_period_end: at_period_end
    rescue Billings::BaseService::Error
      nil
    end

    private

    attr_reader :subscription, :at_period_end
  end
end

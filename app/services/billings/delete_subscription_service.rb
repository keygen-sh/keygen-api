module Billings
  class DeleteSubscriptionService < BaseService

    def initialize(subscription:)
      @subscription = subscription
    end

    def execute
      c = ::Billings::BaseService::Subscription.retrieve subscription
      c.delete at_period_end: true
    rescue ::Billings::BaseService::Error
      nil
    end

    private

    attr_reader :subscription
  end
end

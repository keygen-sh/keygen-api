module Billings
  class UpdateSubscriptionService < BaseService

    def initialize(subscription:, plan:)
      @subscription = subscription
      @plan         = plan
    end

    def execute
      c = ::Billings::BaseService::Subscription.retrieve subscription
      c.plan = plan
      c.save
    rescue ::Billings::BaseService::Error
      nil
    end

    private

    attr_reader :subscription, :plan
  end
end

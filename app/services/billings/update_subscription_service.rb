# frozen_string_literal: true

module Billings
  class UpdateSubscriptionService < BaseService

    def initialize(subscription:, plan:)
      @subscription = subscription
      @plan         = plan
    end

    def execute
      c = Billings::Subscription.retrieve(subscription)

      c.trial_end = 'now'
      c.plan      = plan

      c.save
    rescue Billings::Error
      nil
    end

    private

    attr_reader :subscription, :plan
  end
end

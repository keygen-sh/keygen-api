# frozen_string_literal: true

module Billings
  class UpdateSubscriptionService < BaseService

    def initialize(subscription:, plan:)
      @subscription = subscription
      @plan         = plan
    end

    def call
      s = Billings::Subscription.retrieve(subscription)

      s.trial_end = 'now'
      s.plan      = plan

      s.save
    rescue Billings::Error => e
      Keygen.logger.exception(e)

      nil
    end

    private

    attr_reader :subscription, :plan
  end
end

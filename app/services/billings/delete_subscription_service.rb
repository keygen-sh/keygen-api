# frozen_string_literal: true

module Billings
  class DeleteSubscriptionService < BaseService

    def initialize(subscription:, at_period_end: true)
      @subscription = subscription
      @at_period_end = at_period_end
    end

    def call
      c = Billings::Subscription.retrieve(subscription)
      c.delete(at_period_end: at_period_end)
    rescue Billings::Error => e
      Keygen.logger.exception(e) unless e.code == 'resource_missing'

      nil
    end

    private

    attr_reader :subscription, :at_period_end
  end
end

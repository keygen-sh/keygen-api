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
      error_code = e.json_body.dig(:error, :code) rescue nil

      Keygen.logger.exception(e) unless
        error_code == 'resource_missing'

      nil
    end

    private

    attr_reader :subscription, :at_period_end
  end
end

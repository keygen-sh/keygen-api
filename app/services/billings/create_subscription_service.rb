# frozen_string_literal: true

module Billings
  class CreateSubscriptionService < BaseService

    def initialize(customer:, plan:, trial_end: nil)
      @customer  = customer
      @plan      = plan
      @trial_end = trial_end
    end

    def execute
      Billings::Subscription.create(
        customer: customer,
        trial_end: trial_end,
        plan: plan,
      )
    rescue Billings::Error => e
      Keygen.logger.exception(e)

      nil
    end

    private

    attr_reader :customer, :plan, :trial_end
  end
end

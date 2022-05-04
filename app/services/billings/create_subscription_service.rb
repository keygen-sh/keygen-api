# frozen_string_literal: true

module Billings
  class CreateSubscriptionService < BaseService
    TRIAL_DURATION = 1.month

    def initialize(customer:, plan:, trial_end: nil)
      @customer  = customer
      @plan      = plan
      @trial_end = trial_end
    end

    def call
      Billings::Subscription.create(
        trial_end: trial_end || TRIAL_DURATION.from_now.to_i,
        customer:,
        plan:,
      )
    rescue Billings::Error => e
      Keygen.logger.exception(e)

      nil
    end

    private

    attr_reader :customer,
                :plan,
                :trial_end
  end
end

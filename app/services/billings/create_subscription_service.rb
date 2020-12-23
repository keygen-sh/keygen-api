# frozen_string_literal: true

module Billings
  class CreateSubscriptionService < BaseService

    def initialize(customer:, plan:, trial_end: nil)
      @customer  = customer
      @plan      = plan
      @trial_end = trial_end
    end

    def execute
      params = {
        customer: customer,
        trial_end: trial_end,
        plan: plan
      }

      Billings::BaseService::Subscription.create params
    rescue Billings::BaseService::Error
      nil
    end

    private

    attr_reader :customer, :plan, :trial_end
  end
end

# frozen_string_literal: true

module Billings
  class CreateSubscriptionService < BaseService

    def initialize(customer:, plan:, trial: nil)
      @customer = customer
      @plan     = plan
      @trial    = trial
    end

    def execute
      params = {
        customer: customer,
        trial_end: trial,
        plan: plan
      }

      Billings::BaseService::Subscription.create params
    rescue Billings::BaseService::Error
      nil
    end

    private

    attr_reader :customer, :plan, :trial
  end
end

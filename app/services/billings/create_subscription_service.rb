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
        plan: plan
      }

      params[:trial_end] = trial if !trial.nil? && trial.to_i > 0

      subscription = ::Billings::BaseService::Subscription.create params

      subscription
    rescue ::Billings::BaseService::Error
      nil
    end

    private

    attr_reader :customer, :plan, :trial
  end
end

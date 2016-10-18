module Billings
  class UpdateSubscriptionService < BaseService

    def initialize(id:, plan:)
      @id   = id
      @plan = plan
    end

    def execute
      c = ::Billings::BaseService::Subscription.retrieve id
      c.plan = plan
      c.save
    rescue ::Billings::BaseService::Error
      nil
    end

    private

    attr_reader :id, :plan
  end
end

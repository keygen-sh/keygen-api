module Billings
  class DeleteSubscriptionService < BaseService

    def initialize(id:)
      @id = id
    end

    def execute
      c = ::Billings::BaseService::Subscription.retrieve id
      c.delete at_period_end: true
    rescue ::Billings::BaseService::Error
      nil
    end

    private

    attr_reader :id
  end
end

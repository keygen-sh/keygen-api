# frozen_string_literal: true

module Billings
  class CreateBillingPortalSessionService < BaseService

    def initialize(customer:)
      @customer = customer
    end

    def execute
      Billings::BillingPortal::Session.create(customer: customer)
    rescue Billings::Error
      nil
    end

    private

    attr_reader :customer
  end
end

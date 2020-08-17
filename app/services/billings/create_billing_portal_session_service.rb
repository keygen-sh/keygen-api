# frozen_string_literal: true

module Billings
  class CreateBillingPortalSessionService < BaseService

    def initialize(customer:)
      @customer = customer
    end

    def execute
      Billings::BaseService::BillingPortal::Session.create customer: customer
    rescue Billings::BaseService::Error
      nil
    end

    private

    attr_reader :customer
  end
end

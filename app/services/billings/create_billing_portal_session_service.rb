# frozen_string_literal: true

module Billings
  class CreateBillingPortalSessionService < BaseService

    def initialize(customer:)
      @customer = customer
    end

    def call
      Billings::BillingPortal::Session.create(customer: customer)
    rescue Billings::Error => e
      Keygen.logger.exception(e)

      nil
    end

    private

    attr_reader :customer
  end
end

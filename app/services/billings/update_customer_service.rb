# frozen_string_literal: true

module Billings
  class UpdateCustomerService < BaseService

    def initialize(customer:, token:, coupon:)
      @customer = customer
      @token    = token
      @coupon   = coupon
    end

    def execute
      c = Billings::Customer.retrieve(customer)

      c.card = token unless
        token.nil?

      c.coupon = coupon unless
        coupon.nil?

      c.save
    rescue Billings::Error => e
      Keygen.logger.exception(e)

      nil
    end

    private

    attr_reader :customer, :token, :coupon
  end
end

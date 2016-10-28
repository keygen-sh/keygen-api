module Billings
  class UpdateCustomerService < BaseService

    def initialize(customer:, token:)
      @customer = customer
      @token    = token
    end

    def execute
      c = Billings::BaseService::Customer.retrieve customer
      c.card = token
      c.save
    rescue Billings::BaseService::Error
      nil
    end

    private

    attr_reader :customer, :token
  end
end

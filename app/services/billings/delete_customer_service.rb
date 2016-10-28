module Billings
  class DeleteCustomerService < BaseService

    def initialize(customer:)
      @customer = customer
    end

    def execute
      c = Billings::BaseService::Customer.retrieve customer
      c.delete
    rescue Billings::BaseService::Error
      nil
    end

    private

    attr_reader :customer
  end
end

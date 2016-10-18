module Billings
  class DeleteCustomerService < BaseService

    def initialize(id:)
      @id = id
    end

    def execute
      c = ::Billings::BaseService::Customer.retrieve id
      c.delete
    rescue ::Billings::BaseService::Error
      nil
    end

    private

    attr_reader :id
  end
end

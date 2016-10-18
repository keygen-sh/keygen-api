module Billings
  class UpdateCustomerService < BaseService

    def initialize(id:, token:)
      @id    = id
      @token = token
    end

    def execute
      c = ::Billings::BaseService::Customer.retrieve id
      c.card = token
      c.save
    rescue ::Billings::BaseService::Error
      nil
    end

    private

    attr_reader :id, :token
  end
end

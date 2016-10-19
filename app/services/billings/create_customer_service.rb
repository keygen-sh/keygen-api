module Billings
  class CreateCustomerService < BaseService

    def initialize(account:, token:)
      @account = account
      @token   = token
    end

    def execute
      ::Billings::BaseService::Customer.create(
        description: "#{account.name} (#{account.subdomain}.keygen.sh)",
        token: token
      )
    rescue ::Billings::BaseService::Error
      nil
    end

    private

    attr_reader :account, :token
  end
end

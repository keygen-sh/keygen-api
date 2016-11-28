module Billings
  class CreateCustomerService < BaseService

    def initialize(account:)
      @account = account
    end

    def execute
      Billings::BaseService::Customer.create(
        description: "#{account.company} (#{account.name})",
        email: account.admins.first.email
      )
    rescue Billings::BaseService::Error
      nil
    end

    private

    attr_reader :account
  end
end

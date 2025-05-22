# frozen_string_literal: true

module Billings
  class CreateCustomerService < BaseService

    def initialize(account:, metadata: nil)
      @account  = account
      @metadata = metadata
    end

    def call
      data = { account_id: account.id }
      data.merge!(metadata) if
        metadata.present?

      Billings::Customer.create(
        description: "#{account.name} (#{account.slug})",
        email: account.admins.last.email,
        metadata: data,
      )
    rescue Billings::Error => e
      Keygen.logger.exception(e)

      nil
    end

    private

    attr_reader :account,
                :metadata
  end
end

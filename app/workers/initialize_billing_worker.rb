# frozen_string_literal: true

class InitializeBillingWorker
  include Sidekiq::Worker

  sidekiq_options queue: :billing

  def perform(account_id, referral_id)
    account = Account.find(account_id)
    return unless
      account.billing.nil?

    customer  = Billings::CreateCustomerService.call(account: account, metadata: { referral: referral_id })

    account.create_billing!(
      customer_id: customer.id,
      referral_id: referral_id,
    )
  end
end

class InitializeBillingWorker
  include Sidekiq::Worker

  sidekiq_options queue: :billing

  def perform(account_id)
    account = Account.find account_id

    if account.billing.nil?
      customer = Billings::CreateCustomerService.new(
        account: account
      ).execute

      account.billing = Billing.create!(
        customer_id: customer.id
      )
    end
  end
end

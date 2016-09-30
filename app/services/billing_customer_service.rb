require 'stripe'

class BillingCustomerService

  def initialize(params)
    @id = params[:id]
    @token = params[:token]
    @account = params[:account]
  end

  def create
    external_customer_service.create({
      description: "#{account.name} (#{account.subdomain}.keygin.io)",
      card: token
    })
  rescue external_service_error
    nil
  end

  def update
    c = external_customer_service.retrieve id
    c.card = token
    c.save
  rescue external_service_error
    nil
  end

  def delete
    c = external_customer_service.retrieve id
    c.delete
  rescue external_service_error
    nil
  end

  private

  attr_reader :id, :token, :account

  def external_customer_service
    Stripe::Customer
  end

  def external_service_error
    Stripe::StripeError
  end
end

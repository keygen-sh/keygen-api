require 'stripe'

class CustomerService

  def initialize(params)
    @id = params[:id]
    @token = params[:token]
    @account = params[:account]
  end

  def create
    begin
      external_customer_service.create({
        description: "#{account.name} (#{account.subdomain}.keygin.io)",
        plan: account.plan.external_plan_id,
        card: token
      })
    rescue external_service_error
      false
    end
  end

  def delete
    begin
      c = external_customer_service.retrieve id
      c.delete
    rescue external_service_error
      false
    end
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

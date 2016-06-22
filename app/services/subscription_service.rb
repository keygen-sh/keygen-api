require 'stripe'

class SubscriptionService

  def initialize(params)
    @card = params[:card]
    @amount = params[:amount]
    @email = params[:email]
  end

  def charge
    # begin
      external_charge_service.create charge_attributes
    # rescue Stripe
    #   false
    # end
  end

  def create_customer
    # begin
      external_customer_service.create customer_attributes
    # rescue Stripe
    #   false
    # end
  end

  private

  attr_reader :card, :amount, :email

  def external_charge_service
    Stripe::Charge
  end

  def external_customer_service
    Stripe::Customer
  end

  def charge_attributes
    {
      amount: amount,
      card: card
    }
  end

  def customer_attributes
    {
      email: email,
      card: card
    }
  end
end

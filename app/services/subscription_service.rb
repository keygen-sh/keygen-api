require 'stripe'

class SubscriptionService

  def initialize(params)
    @id = params[:id]
    @customer = params[:customer]
    @plan = params[:plan]
  end

  def create
    begin
      external_subscription_service.create({
        customer: customer,
        plan: plan
      })
    rescue external_service_error
      false
    end
  end

  def update
    begin
      c = external_subscription_service.retrieve id
      c.update plan: plan
    rescue external_service_error
      false
    end
  end

  def delete
    begin
      c = external_subscription_service.retrieve id
      c.delete
    rescue external_service_error
      false
    end
  end

  private

  attr_reader :id, :customer, :plan

  def external_subscription_service
    Stripe::Subscription
  end

  def external_service_error
    Stripe::StripeError
  end
end

require 'stripe'

class BillingSubscriptionService

  def initialize(params)
    @id = params[:id]
    @customer = params[:customer]
    @trial = params[:trial]
    @plan = params[:plan]
  end

  def create
    external_subscription_service.create({
      customer: customer,
      plan: plan
    }.merge(
      # Trial periods are used to keep billing cycles between pausing/resuming
      trial.to_i > 0 ? { trial_end: trial } : {}
    ))
  rescue external_service_error
    nil
  end

  def update
    c = external_subscription_service.retrieve id
    c.plan = plan
    c.save
  rescue external_service_error
    nil
  end

  def delete
    c = external_subscription_service.retrieve id
    c.delete at_period_end: true
  rescue external_service_error
    nil
  end

  private

  attr_reader :id, :customer, :plan, :trial

  def external_subscription_service
    Stripe::Subscription
  end

  def external_service_error
    Stripe::StripeError
  end
end

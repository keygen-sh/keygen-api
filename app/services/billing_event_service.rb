require 'stripe'

class BillingEventService

  def initialize(params)
    @id = params[:id]
  end

  def retrieve
    external_event_service.retrieve id
  rescue external_service_error
    nil
  end

  private

  attr_reader :id

  def external_event_service
    Stripe::Event
  end

  def external_service_error
    Stripe::StripeError
  end
end

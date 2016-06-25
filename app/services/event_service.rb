require 'stripe'

class EventService

  def initialize(params)
    @id = params[:id]
  end

  def retrieve
    begin
      external_event_service.retrieve id
    rescue external_service_error
      false
    end
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

module Api::V1
  class StripeController < Api::V1::BaseController

    # POST /stripe
    def receive_webhook
      skip_authorization

      # Let external service know that we recieved the webhook
      head :accepted

      event = ::Billings::RetrieveEventService.new(id: stripe_params[:id]).execute
      return unless event

      case event.type
      when "customer.subscription.created", "customer.subscription.updated"
        subscription = event.data.object
        billing = Billing.find_by external_customer_id: subscription.customer
        return unless billing

        billing.update({
          external_subscription_period_start: Time.at(subscription.current_period_start),
          external_subscription_period_end: Time.at(subscription.current_period_end),
          external_subscription_id: subscription.id,
          external_subscription_status: subscription.status
        })
      when "customer.subscription.deleted"
        subscription = event.data.object
        billing = Billing.find_by external_customer_id: subscription.customer
        return unless billing&.external_subscription_id == subscription.id

        billing.update({
          external_subscription_period_start: nil,
          external_subscription_period_end: nil,
          external_subscription_id: nil,
          external_subscription_status: subscription.status
        })

        billing.customer.update status: "canceled"
      when "customer.created"
        customer = event.data.object
        billing = Billing.find_by external_customer_id: customer.id
        return unless billing && billing.external_subscription_id.nil?

        subscription = ::Billings::CreateSubscriptionService.new(
          customer: billing.external_customer_id,
          plan: billing.customer.plan.external_plan_id
        ).execute

        billing.customer.update status: subscription.status
      when "customer.updated"
        customer = event.data.object
        billing = Billing.find_by external_customer_id: customer.id
        return unless billing

        card = customer.sources.retrieve customer.default_source
        return unless card

        billing.update({
          card_expiry: DateTime.new(card.exp_year.to_i, card.exp_month.to_i),
          card_brand: card.brand,
          card_last4: card.last4
        })
      when "customer.deleted"
        customer = event.data.object
        billing = Billing.find_by external_customer_id: customer.id
        return unless billing

        billing.customer.update status: "canceled"
        billing.destroy
      end
    end

    private

    def stripe_params
      params
    end
  end
end

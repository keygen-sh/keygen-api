module Api::V1
  class StripeController < Api::V1::BaseController

    # POST /webhooks
    def create
      skip_authorization

      # Let external service know that we recieved the webhook
      head :accepted

      event = EventService.new(id: webhooks_params[:id]).retrieve
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
          external_status: subscription.status
        })
      when "customer.subscription.deleted"
        subscription = event.data.object
        billing = Billing.find_by external_customer_id: subscription.customer
        return unless billing && billing.external_subscription_id == subscription.id

        billing.update({
          external_subscription_period_start: nil,
          external_subscription_period_end: nil,
          external_subscription_id: nil,
          external_status: subscription.status
        })

        billing.customer.update status: "canceled"
      when "customer.created"
        customer = event.data.object
        billing = Billing.find_by external_customer_id: customer.id
        return unless billing

        SubscriptionService.new({
          customer: billing.external_customer_id,
          plan: billing.customer.plan.external_plan_id
        }).create

        billing.customer.update status: "active"
      when "customer.deleted"
        customer = event.data.object
        billing = Billing.find_by external_customer_id: customer.id
        return unless billing

        billing.customer.update status: "canceled"
        billing.destroy
      end
    end

    private

    def webhooks_params
      params
    end
  end
end

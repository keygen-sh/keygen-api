module Api::V1
  class StripeController < Api::V1::BaseController

    # POST /stripe
    def receive_webhook
      skip_authorization

      # Let external service know that we received the webhook
      head :accepted

      event = Billings::RetrieveEventService.new(event: params[:id]).execute
      return unless event

      case event.type
      when "customer.subscription.created", "customer.subscription.updated"
        subscription = event.data.object
        billing = Billing.find_by customer_id: subscription.customer
        return unless billing

        billing.update(
          subscription_period_start: Time.at(subscription.current_period_start),
          subscription_period_end: Time.at(subscription.current_period_end),
          subscription_id: subscription.id,
          subscription_status: subscription.status
        )

        case subscription.status
        when "active"
          billing.activate_subscription unless billing.subscribed?
        when "trialing"
          billing.activate_trial unless billing.trialing?
        when "canceled"
          billing.cancel_subscription unless billing.canceled?
        end

        billing.save
      when "customer.subscription.deleted"
        subscription = event.data.object
        billing = Billing.find_by customer_id: subscription.customer
        return unless billing&.subscription_id == subscription.id

        billing.cancel_subscription! unless billing.paused?
        billing.update(
          subscription_status: subscription.status
        )
      when "customer.source.created", "customer.source.updated"
        card = event.data.object
        billing = Billing.find_by customer_id: card.customer
        return unless billing

        billing.update(
          card_expiry: DateTime.new(card.exp_year.to_i, card.exp_month.to_i),
          card_brand: card.brand,
          card_last4: card.last4
        )
      when "customer.subscription.trial_will_end"
        subscription = event.data.object
        billing = Billing.find_by customer_id: subscription.customer
        return unless billing

        # Make sure our customer knows that they need to add a card to their
        # account within the next few days
        if billing.card.nil?
          AccountMailer.payment_method_missing(account: billing.account).deliver_later
        end
      when "invoice.payment_succeeded"
        invoice = event.data.object
        billing = Billing.find_by customer_id: invoice.customer
        return unless billing && invoice.total > 0

        # Ask for feedback after first successful payment
        if billing.receipts.paid.empty?
          AccountMailer.first_payment_succeeded(account: billing.account).deliver_later
        end

        billing.receipts.create(
          invoice_id: invoice.id,
          amount: invoice.total,
          paid: invoice.paid
        )
      when "invoice.payment_failed"
        invoice = event.data.object
        billing = Billing.find_by customer_id: invoice.customer
        return unless billing

        if billing.card.nil?
          AccountMailer.payment_method_missing(account: billing.account).deliver_later
        else
          AccountMailer.payment_failed(account: billing.account).deliver_later
        end

        billing.receipts.create(
          invoice_id: invoice.id,
          amount: invoice.total,
          paid: invoice.paid
        )
      when "customer.created"
        customer = event.data.object
        billing = Billing.find_by customer_id: customer.id
        return unless billing && billing.subscription_id.nil?

        # Create a trial subscription (possibly without a payment method)
        Billings::CreateSubscriptionService.new(
          customer: billing.customer_id,
          plan: billing.plan.plan_id
        ).execute
      end
    end
  end
end

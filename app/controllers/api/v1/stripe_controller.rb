# frozen_string_literal: true

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

        if subscription.cancel_at_period_end
          billing.cancel_subscription_at_period_end unless billing.canceling?
        else
          case subscription.status
          when "active"
            billing.activate_subscription unless billing.subscribed?
          when "trialing"
            billing.activate_trial unless billing.trialing?
          when "canceled"
            billing.cancel_subscription unless billing.canceled?
          end
        end

        billing.save
      when "customer.subscription.deleted"
        subscription = event.data.object
        billing = Billing.find_by customer_id: subscription.customer
        return unless billing&.subscription_id == subscription.id

        billing.cancel_subscription
        billing.subscription_status = subscription.status

        billing.save
      when "customer.source.created",
           "customer.source.updated",
           "payment_method.attached"
        source = event.data.object
        return unless (source.respond_to?(:object) && source.object == 'card') ||
                      (source.respond_to?(:type) && source.type == 'card')

        # When an ACH bank source is added, it uses a newer webhook structure
        card = if source.respond_to?(:card)
                 source.card
               else
                 source
               end

        billing = Billing.find_by customer_id: source.customer
        return unless billing

        billing.update(
          card_expiry: DateTime.new(card.exp_year, card.exp_month),
          card_brand: card.brand,
          card_last4: card.last4
        )
      when "customer.subscription.trial_will_end"
        subscription = event.data.object
        billing = Billing.find_by customer_id: subscription.customer
        return unless billing && !billing.canceling? && !billing.canceled?

        # Make sure our customer knows that they need to add a card to their
        # account within the next few days
        if billing.card.nil?
          AccountMailer.payment_method_missing(account: billing.account).deliver_later
        end
      when "invoice.payment_succeeded"
        invoice = event.data.object
        billing = Billing.find_by customer_id: invoice.customer
        return unless billing && invoice.total > 0

        # # Ask for feedback after first successful payment
        # if billing.receipts.paid.empty?
        #   AccountMailer.first_payment_succeeded(account: billing.account).deliver_later
        # end

        billing.receipts.create(
          invoice_id: invoice.id,
          amount: invoice.total,
          paid: invoice.paid
        )
      when "invoice.payment_failed"
        invoice = event.data.object
        billing = Billing.find_by customer_id: invoice.customer
        return unless billing && !billing.canceling? && !billing.canceled?

        if billing.card.nil?
          AccountMailer.payment_method_missing(account: billing.account, invoice: invoice).deliver_later
        else
          AccountMailer.payment_failed(account: billing.account, invoice: invoice).deliver_later
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

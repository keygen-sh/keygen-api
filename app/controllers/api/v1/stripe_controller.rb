# frozen_string_literal: true

module Api::V1
  class StripeController < Api::V1::BaseController
    skip_verify_authorized

    def callback
      # let stripe know that we received the webhook
      head :accepted

      event = Billings::RetrieveEventService.call(event: params[:id])
      return unless
        event.present?

      Keygen.logger.info("[stripe] action=receiving event_id=#{event.id} event_type=#{event.type}")

      case event.type
      when "customer.subscription.created",
           "customer.subscription.updated"
        subscription = event.data.object
        billing      = Billing.includes(:account, :plan)
                              .find_by(customer_id: subscription.customer)

        return unless
          billing.present?

        # Update billing's subscription data
        billing.update(
          subscription_period_start: Time.at(subscription.current_period_start),
          subscription_period_end: Time.at(subscription.current_period_end),
          subscription_id: subscription.id,
          subscription_status: subscription.status,
        )

        # FIXME(ezekg) Remove begin/rescue block after we confirm working
        # Update account plan if changed
        begin
          account = billing.account
          plan_id = subscription.items.first.plan.id

          if account.plan.plan_id != plan_id
            plan = Plan.find_by(plan_id: plan_id)
            if plan.present?
              Keygen.logger.warn("[stripe] action=change_plan event_id=#{event.id} account_id=#{account.id} plan_id=#{plan.id} old_plan_sid=#{account.plan.plan_id} new_plan_sid=#{plan_id}")

              account.update(plan: plan)
            else
              Keygen.logger.warn("[stripe] action=change_plan event_id=#{event.id} account_id=#{account.id} plan_id=N/A old_plan_sid=#{account.plan.plan_id} new_plan_sid=#{plan_id}")
            end
          end
        rescue => e
          Keygen.logger.exception(e)
        end

        # Update billing state machine
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
          card_added_at: Time.current,
          card_expiry: DateTime.new(card.exp_year, card.exp_month),
          card_brand: card.brand,
          card_last4: card.last4
        )
      when "customer.subscription.trial_will_end"
        subscription = event.data.object
        billing = Billing.find_by customer_id: subscription.customer
        return unless billing && !billing.canceling? && !billing.canceled?

        account = billing.account
        return if account.last_trial_will_end_sent_at.present?

        request_count_for_week = account.request_logs.where('request_logs.created_at > ?', 1.week.ago).count

        # Let the active account know that their trial is going to be ending
        if request_count_for_week > 0
          account.touch(:last_trial_will_end_sent_at)

          if billing.card.nil?
            PlaintextMailer.trial_ending_soon_without_payment_method(account: account).deliver_later
          else
            PlaintextMailer.trial_ending_soon_with_payment_method(account: account).deliver_later
          end
        end
      when "invoice.payment_succeeded"
        invoice = event.data.object
        billing = Billing.find_by customer_id: invoice.customer
        return unless billing.present? &&
                      invoice.total > 0

        successful_payment_count = billing.receipts.paid.count + 1
        account = billing.account

        if successful_payment_count == 1
          PlaintextMailer.first_payment_succeeded(account: account).deliver_later
        end

        if successful_payment_count >= 3 && account.last_prompt_for_review_sent_at.nil?
          account.touch :last_prompt_for_review_sent_at

          if rand(0..1).zero?
            PlaintextMailer.prompt_for_testimonial(account: account).deliver_later
          else
            PlaintextMailer.prompt_for_review(account: account).deliver_later
          end
        end

        billing.receipts.create(
          invoice_id: invoice.id,
          amount: invoice.total,
          paid: invoice.paid
        )
      when "invoice.payment_failed"
        invoice = event.data.object
        billing = Billing.find_by customer_id: invoice.customer
        return unless billing && !billing.canceling? && !billing.canceled?

        if billing.card.present?
          AccountMailer.payment_failed(account: billing.account, invoice: invoice.to_hash).deliver_later
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
        Billings::CreateSubscriptionService.call(
          customer: billing.customer_id,
          plan: billing.plan.plan_id
        )
      end

      Keygen.logger.info("[stripe] action=received event_id=#{event.id} event_type=#{event.type}")
    end
  end
end

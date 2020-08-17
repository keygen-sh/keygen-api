# frozen_string_literal: true

module Api::V1::Accounts::Actions
  class SubscriptionController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :authenticate_with_token!
    before_action :set_account

    def manage
      authorize @account

      session = Billings::CreateBillingPortalSessionService.new(customer: @account.billing.customer_id).execute

      if session
        redirect_to session.url, status: 303
      else
        render_unprocessable_entity detail: "failed to generate a subscription management session"
      end
    end

    # POST /accounts/1/actions/pause-subscription
    def pause
      authorize @account

      if @account.pause_subscription!
        CreateWebhookEventService.new(
          event: "account.subscription.paused",
          account: @account,
          resource: @account
        ).execute

        render_meta status: "paused"
      else
        render_unprocessable_entity detail: "failed to pause #{@account.billing.state} subscription", source: {
          pointer: "/data/relationships/billing" }
      end
    end

    # POST /accounts/1/actions/resume-subscription
    def resume
      authorize @account

      if @account.resume_subscription!
        CreateWebhookEventService.new(
          event: "account.subscription.resumed",
          account: @account,
          resource: @account
        ).execute

        render_meta status: "resumed"
      else
        render_unprocessable_entity detail: "failed to resume #{@account.billing.state} subscription", source: {
          pointer: "/data/relationships/billing" }
      end
    end

    # POST /accounts/1/actions/cancel-subscription
    def cancel
      authorize @account

      if @account.cancel_subscription_at_period_end!
        CreateWebhookEventService.new(
          event: "account.subscription.canceled",
          account: @account,
          resource: @account
        ).execute

        render_meta status: "canceling"
      else
        render_unprocessable_entity detail: "failed to cancel #{@account.billing.state} subscription", source: {
          pointer: "/data/relationships/billing" }
      end
    end

    # POST /accounts/1/actions/renew-subscription
    def renew
      authorize @account

      if @account.renew_subscription!
        CreateWebhookEventService.new(
          event: "account.subscription.renewed",
          account: @account,
          resource: @account
        ).execute

        render_meta status: "renewed"
      else
        render_unprocessable_entity detail: "failed to renew #{@account.billing.state} subscription", source: {
          pointer: "/data/relationships/billing" }
      end
    end

    private

    def set_account
      @account = @current_account
    end
  end
end

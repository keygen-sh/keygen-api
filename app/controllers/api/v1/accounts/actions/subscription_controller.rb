module Api::V1::Accounts::Actions
  class SubscriptionController < Api::V1::BaseController
    before_action :authenticate_with_token!
    before_action :set_account, only: [:pause, :resume, :cancel]

    # POST /accounts/1/actions/pause
    def pause
      authorize @account

      if @account.status == "paused"
        render_unprocessable_entity detail: "is already paused", source: {
          pointer: "/data/attributes/status" } and return
      end

      # TODO: Save last billed date for resuming subscription with current billing cycle
      subscription = SubscriptionService.new({
        id: @account.billing.external_subscription_id
      }).delete

      if subscription
        @account.billing.external_subscription_id = nil
        @account.billing.status = subscription.status
        @account.status = "paused"

        if @account.save
          render_meta status: "paused"
        else
          render_unprocessable_resource @account
        end
      else
        render_unprocessable_entity detail: "subscription is invalid", source: {
          pointer: "/data/attributes/billing" }
      end
    end

    # POST /accounts/1/actions/resume
    def resume
      authorize @account

      if @account.status == "active"
        render_unprocessable_entity detail: "is already active", source: {
          pointer: "/data/attributes/status" } and return
      end

      # TODO: Use last billed date to resume subscription with previous billing cycle
      subscription = SubscriptionService.new({
        customer: @account.billing.external_customer_id,
        plan: @account.plan.external_plan_id
      }).create

      if subscription
        @account.billing.external_subscription_id = subscription.id
        @account.billing.status = subscription.status
        @account.status = "active"

        if @account.save
          render_meta status: "active"
        else
          render_unprocessable_resource @account
        end
      else
        render_unprocessable_entity detail: "subscription is invalid", source: {
          pointer: "/data/attributes/billing" }
      end
    end

    # POST /accounts/1/actions/cancel
    def cancel
      authorize @account

      if @account.status == "canceled"
        render_unprocessable_entity detail: "is already canceled", source: {
          pointer: "/data/attributes/status" } and return
      end

      subscription = SubscriptionService.new({
        id: @account.billing.external_subscription_id
      }).delete

      if subscription
        @account.billing.external_subscription_id = nil
        @account.billing.status = subscription.status
        @account.status = "canceled"

        if @account.save
          render_meta status: "canceled"
        else
          render_unprocessable_resource @account
        end
      else
        render_unprocessable_entity detail: "subscription is invalid", source: {
          pointer: "/data/attributes/billing" }
      end
    end

    private

    def set_account
      @account = Account.find_by_hashid params[:account_id]
      @account || render_not_found
    end
  end
end

module Api::V1::Accounts::Actions
  class SubscriptionController < Api::V1::BaseController
    before_action :authenticate_with_token!
    before_action :set_account

    # POST /accounts/1/actions/pause-subscription
    def pause
      authorize @account

      if @account.pause_subscription!
        CreateWebhookEventService.new(
          event: "account.paused",
          account: @account,
          resource: @account
        ).execute

        render_meta status: "paused"
      else
        render_unprocessable_entity detail: "failed to pause subscription", source: {
          pointer: "/data/relationships/billing" }
      end
    end

    # POST /accounts/1/actions/resume-subscription
    def resume
      authorize @account

      if @account.resume_subscription!
        CreateWebhookEventService.new(
          event: "account.resumed",
          account: @account,
          resource: @account
        ).execute

        render_meta status: "resumed"
      else
        render_unprocessable_entity detail: "failed to resume subscription", source: {
          pointer: "/data/relationships/billing" }
      end
    end

    # POST /accounts/1/actions/cancel-subscription
    def cancel
      authorize @account

      if @account.cancel_subscription!
        CreateWebhookEventService.new(
          event: "account.canceled",
          account: @account,
          resource: @account
        ).execute

        render_meta status: "canceled"
      else
        render_unprocessable_entity detail: "failed to cancel subscription", source: {
          pointer: "/data/relationships/billing" }
      end
    end

    # POST /accounts/1/actions/renew-subscription
    def renew
      authorize @account

      if @account.renew_subscription!
        CreateWebhookEventService.new(
          event: "account.renewed",
          account: @account,
          resource: @account
        ).execute

        render_meta status: "renewed"
      else
        render_unprocessable_entity detail: "failed to renew subscription", source: {
          pointer: "/data/relationships/billing" }
      end
    end

    private

    def set_account
      @account = Account.find params[:id]
    end
  end
end

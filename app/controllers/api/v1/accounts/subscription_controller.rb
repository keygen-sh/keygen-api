module Api::V1::Accounts
  class SubscriptionController < Api::V1::BaseController
    before_action :authenticate_with_token!
    before_action :set_account

    # POST /accounts/1/pause-subscription
    def pause
      render_not_found and return unless @account

      authorize @account

      if @account.pause_subscription
        render_meta status: "paused"
      else
        render_unprocessable_entity detail: "failed to pause subscription", source: {
          pointer: "/data/relationships/billing" }
      end
    end

    # POST /accounts/1/resume-subscription
    def resume
      render_not_found and return unless @account

      authorize @account

      if @account.resume_subscription
        render_meta status: "resumed"
      else
        render_unprocessable_entity detail: "failed to resume subscription", source: {
          pointer: "/data/relationships/billing" }
      end
    end

    # POST /accounts/1/cancel-subscription
    def cancel
      render_not_found and return unless @account

      authorize @account

      if @account.cancel_subscription
        render_meta status: "canceled"
      else
        render_unprocessable_entity detail: "failed to cancel subscription", source: {
          pointer: "/data/relationships/billing" }
      end
    end

    # POST /accounts/1/renew-subscription
    def renew
      render_not_found and return unless @account

      authorize @account

      if @account.renew_subscription
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

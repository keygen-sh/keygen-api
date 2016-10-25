module Api::V1::Accounts::Actions
  class SubscriptionController < Api::V1::BaseController
    before_action :authenticate_with_token!
    before_action :set_account

    # POST /accounts/1/actions/pause
    def pause
      render_not_found and return unless @account

      authorize @account

      if @account.pause_subscription
        render_meta status: "paused"
      else
        render_unprocessable_resource @account
      end
    end

    # POST /accounts/1/actions/resume
    def resume
      render_not_found and return unless @account

      authorize @account

      if @account.resume_subscription
        render_meta status: "resumed"
      else
        render_unprocessable_resource @account
      end
    end

    # POST /accounts/1/actions/cancel
    def cancel
      render_not_found and return unless @account

      authorize @account

      if @account.cancel_subscription
        render_meta status: "canceled"
      else
        render_unprocessable_resource @account
      end
    end

    # POST /accounts/1/actions/renew
    def renew
      render_not_found and return unless @account

      authorize @account

      if @account.renew_subscription
        render_meta status: "renewed"
      else
        render_unprocessable_resource @account
      end
    end

    private

    def set_account
      @account = Account.find_by_hashid params[:account_id]
    end
  end
end

module Api::V1::Accounts::Actions
  class StatusController < BaseController
    before_action :set_account, only: [:pause, :resume, :cancel]

    # accessible_by_admin :pause, :resume, :cancel

    # POST /accounts/1/actions/pause
    def pause
      if @account.update(status: "paused")
        render json: @account
      else
        render json: @account, status: :unprocessable_entity, adapter: :json_api, serializer: ActiveModel::Serializer::ErrorSerializer
      end
    end

    # POST /accounts/1/actions/resume
    def resume
      if @account.update(status: "active")
        render json: @account
      else
        render json: @account, status: :unprocessable_entity, adapter: :json_api, serializer: ActiveModel::Serializer::ErrorSerializer
      end
    end

    # POST /accounts/1/actions/cancel
    def cancel
      if @account.update(status: "cancelled")
        render json: @account
      else
        render json: @account, status: :unprocessable_entity, adapter: :json_api, serializer: ActiveModel::Serializer::ErrorSerializer
      end
    end

    private

    def set_account
      @account = Account.find_by_hashid params[:account_id]
    end
  end
end

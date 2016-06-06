module Api::V1
  class AccountsController < BaseController
    before_action :set_account, only: [:show, :update, :destroy]

    accessible_by_nobody :index
    accessible_by_public :create
    accessible_by_account_admin :show, :update, :destroy

    # GET /accounts
    def index
      @accounts = Account.all

      render json: @accounts
    end

    # GET /accounts/1
    def show
      render json: @account
    end

    # POST /accounts
    def create
      @account = Account.new account_params

      if @account.save
        render json: @account, status: :created, location: v1_account_url(@account)
      else
        render json: @account, status: :unprocessable_entity, adapter: :json_api, serializer: ActiveModel::Serializer::ErrorSerializer
      end
    end

    # PATCH/PUT /accounts/1
    def update
      if @account.update(account_params)
        render json: @account
      else
        render json: @account, status: :unprocessable_entity, adapter: :json_api, serializer: ActiveModel::Serializer::ErrorSerializer
      end
    end

    # DELETE /accounts/1
    def destroy
      @account.destroy
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_account
      @account = Account.find_by_hashid params[:id]
    end

    # Only allow a trusted parameter "white list" through.
    def account_params
      params.require(:account).permit :name, :email, :subdomain, :plan
    end
  end
end

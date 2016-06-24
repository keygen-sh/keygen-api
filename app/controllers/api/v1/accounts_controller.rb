module Api::V1
  class AccountsController < Api::V1::BaseController
    has_scope :plan
    has_scope :page, type: :hash

    before_action :authenticate_with_token!, only: [:show, :update, :destroy]
    before_action :set_account, only: [:show, :update, :destroy]

    # GET /accounts
    def index
      @accounts = apply_scopes(Account).all
      authorize @accounts

      render json: @accounts
    end

    # GET /accounts/1
    def show
      authorize @account

      render json: @account
    end

    # POST /accounts
    def create
      plan = Plan.find_by_hashid(account_params[:plan])

      @account = Account.new account_params.merge(plan: plan)
      authorize @account

      # Check if account is valid thus far before billing customer
      unless @account.valid?
        render_unprocessable_resource @account and return
      end

      # Subscribes and charges customer if successful
      billing = create_billing_with_external_service
      @account.billing = billing

      if @account.save
        render json: @account, status: :created, location: v1_account_url(@account)
      else
        render_unprocessable_resource @account
      end
    end

    # PATCH/PUT /accounts/1
    def update
      authorize @account

      if @account.update(account_params)
        render json: @account
      else
        render_unprocessable_resource @account
      end
    end

    # DELETE /accounts/1
    def destroy
      authorize @account

      @account.destroy
    end

    private

    def create_billing_with_external_service
      billing = Billing.new
      customer = CustomerService.new(
        billing_params.merge(account: @account)
      ).create

      if customer
        billing.external_customer_id = customer.id
        billing.external_subscription_id = customer.subscriptions.data.first.id
        billing.status = customer.subscriptions.data.first.status
      end

      billing
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_account
      @account = Account.find_by_hashid params[:id]
      @account || render_not_found
    end

    # Only allow a trusted parameter "white list" through.
    def account_params
      params.require(:account).permit :name, :subdomain, :plan,
        users_attributes: [[:name, :email, :password]]
    end

    def billing_params
      params.require(:billing).permit :token
    end
  end
end

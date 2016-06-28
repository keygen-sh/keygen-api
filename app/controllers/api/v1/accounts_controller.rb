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

      # Check if account is valid thus far before creating customer
      render_unprocessable_resource @account and return unless @account.valid?

      # Create a new customer and partial billing model
      billing = Billing.new

      if customer = create_customer_with_external_service
        billing.external_customer_id = customer.id

        # We expect to recieve a 'customer.created' webhook, and from there we
        # will subscribe the customer to their chosen plan and charge them;
        # setting the statuses to pending lets the customer use the API
        # until we recieve the status of the charge.
        billing.external_status = "pending"
        @account.status = "pending"
      end

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

    # TODO: Clean this up
    attr_reader :_raw_params, :_account_params, :_billing_params

    def create_customer_with_external_service
      return false unless billing_params
      CustomerService.new(
        billing_params.merge account: @account
      ).create
    end

    def set_account
      @account = Account.find_by_hashid params[:id]
      @account || render_not_found
    end

    def _params
      @_raw_params ||= params.require(:account).permit :name, :subdomain, :plan, {
        users: [[:name, :email, :password]],
      }.merge(
        action_name == "create" ? { billing: [:token] } : {}
      )
    end

    def _split_params!
      return unless @_billing_params.nil? && @_account_params.nil?

      # Rename users params
      _params[:users_attributes] = _params.delete :users if _params[:users]

      # Split up billing and account params
      @_billing_params ||= _params.delete :billing if _params[:billing]
      @_account_params ||= _params
    end

    def account_params
      _split_params!; @_account_params
    end

    def billing_params
      _split_params!; @_billing_params
    end
  end
end

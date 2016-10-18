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
      render_not_found and return unless @account

      authorize @account

      render json: @account
    end

    # POST /accounts
    def create
      plan = Plan.find_by_hashid account_params[:plan]

      @account = Account.new account_params.merge(plan: plan)
      authorize @account

      # Check if account is valid thus far before creating customer
      render_unprocessable_resource @account and return unless @account.valid?

      # Create a new customer and partial billing model
      billing = Billing.new

      if !billing_params.nil?
        customer = ::Billings::CreateCustomerService.new(
          account: @account,
          token: billing_params[:token]
        ).execute

        if !customer.nil?
          billing.external_customer_id = customer.id

          # We expect to recieve a 'customer.created' webhook, and from there we
          # will subscribe the customer to their chosen plan and charge them;
          # setting the statuses to pending lets the customer use the API
          # until we recieve the status of the charge.
          billing.external_subscription_status = "pending"
          @account.status = "pending"
        end
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
      render_not_found and return unless @account

      authorize @account

      if @account.update(account_params)
        render json: @account
      else
        render_unprocessable_resource @account
      end
    end

    # DELETE /accounts/1
    def destroy
      render_not_found and return unless @account

      authorize @account

      @account.destroy
    end

    private

    def set_account
      @account = Account.find_by_hashid params[:id]
    end

    def account_params
      permitted_params[:account]
    end

    def billing_params
      permitted_params[:billing]
    end

    attr_accessor :permitted_params

    def permitted_params
      @permitted_params ||= Proc.new do
        schema = params.require(:account).tap do |param|
          additional = {}
          permits = []

          permits << :name
          permits << :subdomain

          if action_name == "create"
            permits << :plan
            additional.merge! admins: [[:name, :email, :password]]
            additional.merge! billing: [:token]
          end

          param.permit *permits, additional
        end.to_unsafe_hash

        permitted = {}

        # Split up params
        permitted[:billing] = schema.delete :billing
        permitted[:account] = schema

        # Swap `admins` key with `users_attributes`
        if permitted[:account].key? :admins
          permitted[:account][:users_attributes] = permitted[:account].delete :admins
        end

        permitted
      end.call
    end
  end
end

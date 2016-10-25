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
      permitted_params
    end

    attr_accessor :permitted_params

    def permitted_params
      @permitted_params ||= Proc.new do
        schema = params.require(:account).tap do |param|
          permits = []

          permits << :name
          permits << :subdomain

          if action_name == "create"
            permits << :plan
            permits << { admins: [[:name, :email, :password]] }
          end

          param.permit *permits
        end.transform_keys! { |key|
          case key
          when "admins"
            "users_attributes"
          else
            key
          end
        }.to_unsafe_h

        # Ensure all founding users are admins
        schema[:users_attributes]&.map! do |user|
          user.merge! roles_attributes: [{ name: "admin" }]
        end

        schema
      end.call
    end
  end
end

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
      plan = Plan.find_by_hashid account_parameters[:plan]

      @account = Account.new account_parameters.merge(plan: plan)
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

      if @account.update(account_parameters)
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

    attr_reader :parameters

    def set_account
      @account = Account.find_by_hashid params[:id]
    end

    def account_parameters
      parameters[:account]
    end

    def parameters
      @parameters ||= TypedParameters.build self do
        options strict: true

        on :create do
          param :account, type: :hash do
            param :name, type: :string
            param :subdomain, type: :string
            param :plan, type: :string
            param :users_attributes, type: :array, as: :admins do
              item type: :hash do
                param :name, type: :string
                param :email, type: :string
                param :password, type: :string
              end
            end
          end
        end

        on :update do
          param :account, type: :hash do
            param :name, type: :string, optional: true
            param :subdomain, type: :string, optional: true
          end
        end
      end
    end
  end
end

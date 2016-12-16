module Api::V1
  class AccountsController < Api::V1::BaseController
    include TypedParameters::ControllerMethods

    has_scope :plan

    before_action :authenticate_with_token!, only: [:show, :update, :destroy]
    before_action :set_account, only: [:show, :update, :destroy]

    # GET /accounts
    def index
      @accounts = apply_scopes(Account).all
      authorize @accounts

      render jsonapi: @accounts
    end

    # GET /accounts/1
    def show
      render_not_found and return unless @account

      authorize @account

      render jsonapi: @account
    end

    # POST /accounts
    def create
      @account = Account.new account_params
      authorize @account

      if @account.save
        render jsonapi: @account, status: :created, location: v1_account_url(@account)
      else
        render_unprocessable_resource @account
      end
    end

    # PATCH/PUT /accounts/1
    def update
      render_not_found and return unless @account

      authorize @account

      if @account.update(account_params)
        render jsonapi: @account
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
      @account = Account.find params[:id]
    end

    typed_parameters transform: true do
      options strict: true

      on :create do
        param :data, type: :hash do
          param :type, type: :string, inclusion: %w[account accounts]
          param :attributes, type: :hash do
            param :name, type: :string
            param :slug, type: :string
          end
          param :relationships, type: :hash do
            param :plan, type: :hash do
              param :data, type: :hash do
                param :type, type: :string, inclusion: %w[plan plans]
                param :id, type: :string
              end
            end
            param :admins, type: :hash do
              param :data, type: :array do
                items type: :hash do
                  param :type, type: :string, inclusion: %w[user users]
                  param :attributes, type: :hash do
                    param :name, type: :string
                    param :email, type: :string
                    param :password, type: :string
                  end
                end
              end
            end
          end
        end
      end

      on :update do
        param :data, type: :hash do
          param :type, type: :string, inclusion: %w[account accounts]
          param :attributes, type: :hash do
            param :name, type: :string, optional: true
            param :slug, type: :string, optional: true
          end
        end
      end
    end
  end
end

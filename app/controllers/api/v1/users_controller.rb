# frozen_string_literal: true

module Api::V1
  class UsersController < Api::V1::BaseController
    has_scope :roles, type: :array, default: [:user]
    has_scope :active
    has_scope :product

    before_action :scope_to_current_account!
    before_action :require_active_subscription!, only: [:index, :create, :destroy]
    before_action :authenticate_with_token!, only: [:index, :show, :update, :destroy]
    before_action :authenticate_with_token, only: [:create]
    before_action :set_user, only: [:show, :update, :destroy]

    # GET /users
    def index
      @users = policy_scope apply_scopes(current_account.users.eager_load(:role))
      authorize @users

      render jsonapi: @users
    end

    # GET /users/1
    def show
      authorize @user

      render jsonapi: @user
    end

    # POST /users
    def create
      @user = current_account.users.new user_params
      authorize @user

      if @user.save
        CreateWebhookEventService.new(
          event: "user.created",
          account: current_account,
          resource: @user
        ).execute

        render jsonapi: @user, status: :created, location: v1_account_user_url(@user.account, @user)
      else
        render_unprocessable_resource @user
      end
    end

    # PATCH/PUT /users/1
    def update
      authorize @user

      if @user.update(user_params)
        CreateWebhookEventService.new(
          event: "user.updated",
          account: current_account,
          resource: @user
        ).execute

        render jsonapi: @user
      else
        render_unprocessable_resource @user
      end
    end

    # DELETE /users/1
    def destroy
      authorize @user

      if @user.destroy_async
        CreateWebhookEventService.new(
          event: "user.deleted",
          account: current_account,
          resource: @user
        ).execute

        head :no_content
      else
        render_unprocessable_resource @user
      end
    end

    private

    def set_user
      @user = current_account.users.sluggable_find! params[:id]

      raise Keygen::Error::NotFoundError.new(model: User.name, id: params[:id]) if @user.nil?
    end

    typed_parameters transform: true do
      options strict: true

      on :create do
        param :data, type: :hash do
          param :type, type: :string, inclusion: %w[user users]
          param :attributes, type: :hash do
            param :first_name, type: :string
            param :last_name, type: :string
            param :email, type: :string
            param :password, type: :string
            param :metadata, type: :hash, optional: true
            if current_bearer&.has_role?(:admin)
              param :role, type: :string, inclusion: %w[user admin developer sales-agent support-agent], optional: true, transform: -> (k, v) {
                [:role_attributes, { name: v.underscore }]
              }
            end
          end
        end
      end

      on :update do
        param :data, type: :hash do
          param :type, type: :string, inclusion: %w[user users]
          param :id, type: :string, inclusion: [controller.params[:id]], optional: true, transform: -> (k, v) { [] }
          param :attributes, type: :hash, optional: true do
            param :first_name, type: :string, optional: true
            param :last_name, type: :string, optional: true
            param :email, type: :string, optional: true
            if current_bearer&.has_role?(:admin, :product)
              param :password, type: :string, optional: true
            end
            if current_bearer&.has_role?(:admin, :developer, :sales_agent, :product)
              param :metadata, type: :hash, optional: true
            end
            if current_bearer&.has_role?(:admin)
              param :role, type: :string, inclusion: %w[user admin developer sales-agent support-agent], optional: true, transform: -> (k, v) {
                [:role_attributes, { name: v.underscore }]
              }
            end
          end
        end
      end
    end
  end
end

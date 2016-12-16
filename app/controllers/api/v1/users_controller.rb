module Api::V1
  class UsersController < Api::V1::BaseController
    has_scope :roles, type: :array, default: [:user]
    has_scope :product

    before_action :scope_to_current_account!
    before_action :authenticate_with_token!, only: [:index, :show, :update, :destroy]
    before_action :authenticate_with_token, only: [:create]
    before_action :set_user, only: [:show, :update, :destroy]

    # GET /users
    def index
      @users = policy_scope apply_scopes(current_account.users).all
      authorize @users

      render jsonapi: @users
    end

    # GET /users/1
    def show
      render_not_found and return unless @user

      authorize @user

      render jsonapi: @user
    end

    # POST /users
    def create
      @user = current_account.users.new user_attributes.merge(user_relationships)
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
      render_not_found and return unless @user

      authorize @user

      if @user.update(user_attributes.merge(user_relationships))
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
      render_not_found and return unless @user

      authorize @user

      CreateWebhookEventService.new(
        event: "user.deleted",
        account: current_account,
        resource: @user
      ).execute

      @user.destroy
    end

    private

    attr_reader :parameters

    def set_user
      @user = current_account.users.find_by id: params[:id]
    end

    def user_attributes
      parameters[:data][:attributes] || {}
    end

    def user_relationships
      parameters[:data][:relationships] || {}
    end

    def parameters
      @parameters ||= TypedParameters.build self do
        options strict: true

        on :create do
          param :data, type: :hash do
            param :type, type: :string, inclusion: %w[user users]
            param :attributes, type: :hash do
              param :name, type: :string
              param :email, type: :string
              param :password, type: :string
              if current_bearer&.role? :admin or current_bearer&.role? :product
                param :metadata, type: :hash, optional: true
              end
            end
            param :relationships, type: :hash, optional: true do
              if current_bearer&.role? :admin
                param :role_attributes, type: :hash, as: :role, optional: true do
                  param :name, type: :string, inclusion: %w[user admin]
                end
              end
            end
          end
        end

        on :update do
          param :data, type: :hash do
            param :type, type: :string, inclusion: %w[user users]
            param :attributes, type: :hash, optional: true do
              param :name, type: :string, optional: true
              param :email, type: :string, optional: true
              if current_bearer&.role? :admin or current_bearer&.role? :product
                param :metadata, type: :hash, optional: true
              end
            end
            param :relationships, type: :hash, optional: true do
              if current_bearer&.role? :admin
                param :role_attributes, type: :hash, as: :role, optional: true do
                  param :name, type: :string, inclusion: %w[user admin]
                end
              end
            end
          end
        end
      end
    end
  end
end

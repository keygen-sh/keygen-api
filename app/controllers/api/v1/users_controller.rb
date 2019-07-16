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
      json = Rails.cache.fetch(cache_key, expires_in: 1.minute) do
        users = policy_scope apply_scopes(current_account.users.eager_load(:role))
        authorize users

        cache_status = :miss
        data = JSONAPI::Serializable::Renderer.new.render(users, {
          expose: { url_helpers: Rails.application.routes.url_helpers },
          class: {
            Account: SerializableAccount,
            Token: SerializableToken,
            Product: SerializableProduct,
            Policy: SerializablePolicy,
            User: SerializableUser,
            License: SerializableLicense,
            Machine: SerializableMachine,
            Key: SerializableKey,
            Billing: SerializableBilling,
            Plan: SerializablePlan,
            WebhookEndpoint: SerializableWebhookEndpoint,
            WebhookEvent: SerializableWebhookEvent,
            Metric: SerializableMetric,
            Error: SerializableError
          }
        })

        data.tap do |d|
          links = pagination_links(users)

          d[:links] = links unless links.empty?
        end
      end

      # Skip auth when he have a cache hit
      skip_authorization if cached?

      render json: json
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
      @user =
        if params[:id] =~ UUID_REGEX
          current_account.users.find_by id: params[:id]
        else
          current_account.users.find_by email: params[:id].downcase
        end

      raise Keygen::Error::NotFoundError.new(model: User.name, id: params[:id]) if @user.nil?
    end

    # TODO(ezekg) Extract this out into a caching module since it's duplicated
    #             across quite a few different controllers.
    def cache_key
      [:users, current_account.id, current_bearer.id, request.query_string.parameterize].select(&:present?).join ":"
    end

    def cache_status=(status)
      @cache_status = status
    end

    def cache_status
      @cache_status ||= :hit
    end

    def cached?
      cache_status == :hit
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
            if current_bearer&.role? :admin
              param :role, type: :string, inclusion: %w[user admin], optional: true, transform: -> (k, v) {
                [:role_attributes, { name: v }]
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
            if current_bearer&.role? :admin or current_bearer&.role? :product
              param :password, type: :string, optional: true
              param :metadata, type: :hash, optional: true
            end
            if current_bearer&.role? :admin
              param :role, type: :string, inclusion: %w[user admin], optional: true, transform: -> (k, v) {
                [:role_attributes, { name: v }]
              }
            end
          end
        end
      end
    end
  end
end

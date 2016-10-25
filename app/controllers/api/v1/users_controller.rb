module Api::V1
  class UsersController < Api::V1::BaseController
    has_scope :roles, type: :array, default: [:user]
    has_scope :product
    has_scope :page, type: :hash

    before_action :scope_by_subdomain!
    before_action :authenticate_with_token!, only: [:index, :show, :update, :destroy]
    before_action :authenticate_with_token, only: [:create]
    before_action :set_user, only: [:show, :update, :destroy]

    # GET /users
    def index
      @users = policy_scope apply_scopes(current_account.users).all
      authorize @users

      render json: @users
    end

    # GET /users/1
    def show
      render_not_found and return unless @user

      authorize @user

      render json: @user
    end

    # POST /users
    def create
      @user = current_account.users.new user_params
      authorize @user

      if @user.save
        WebhookEventService.new(
          event: "user.created",
          account: current_account,
          resource: @user
        ).execute

        render json: @user, status: :created, location: v1_user_url(@user)
      else
        render_unprocessable_resource @user
      end
    end

    # PATCH/PUT /users/1
    def update
      render_not_found and return unless @user

      authorize @user

      if @user.update(user_params)
        WebhookEventService.new(
          event: "user.updated",
          account: current_account,
          resource: @user
        ).execute

        render json: @user
      else
        render_unprocessable_resource @user
      end
    end

    # DELETE /users/1
    def destroy
      render_not_found and return unless @user

      authorize @user

      WebhookEventService.new(
        event: "user.deleted",
        account: current_account,
        resource: @user
      ).execute

      @user.destroy
    end

    private

    def set_user
      @user = current_account.users.find_by_hashid params[:id]
    end

    def user_params
      permitted_params
    end

    attr_accessor :permitted_params

    def permitted_params
      @permitted_params ||= Proc.new do
        schema = params.require(:user).tap do |param|
          permits = []

          permits << :name
          permits << :email

          if action_name == "create"
            permits << :password
          end

          if current_bearer&.role? :admin
            permits << { roles: [[:name]] }
          end

          # TODO: Possibly unsafe. See: http://stackoverflow.com/questions/17810838/strong-parameters-permit-all-attributes-for-nested-attributes
          permits << {
            meta: params.to_unsafe_h.fetch(:user, {}).fetch(:meta, {}).keys.map(&:to_sym)
          }

          param.permit *permits
        end.transform_keys! { |key|
          case key
          when "roles"
            "roles_attributes"
          else
            key
          end
        }.to_unsafe_h

        schema
      end.call
    end
  end
end

module Api::V1::Licenses::Relationships
  class UsersController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_license

    # GET /licenses/1/user
    def show
      @user = @license.user
      authorize @user

      render jsonapi: @user
    end

    # PUT /licenses/1/user
    def update
      authorize @license, :transfer?

      user = current_account.users.find_by id: user_params[:id]
      if user.nil?
        return render_unprocessable_entity(
          detail: "user must exist",
          source: {
            pointer: "/data/id"
          }
        )
      end

      if @license.update(user: user)
        CreateWebhookEventService.new(
          event: "license.user.updated",
          account: current_account,
          resource: @license
        ).execute

        render jsonapi: @license
      else
        render_unprocessable_resource @license
      end
    end

    private

    def set_license
      # FIXME(ezekg) This allows the license to be looked up by ID or
      #              key, but this is pretty messy.
      id = params[:license_id] if params[:license_id] =~ UUID_REGEX # Only include when it's a UUID (else pg throws an err)
      key = params[:license_id]

      @license = current_account.licenses.where("id = ? OR key = ?", id, key).first
      raise ActiveRecord::RecordNotFound if @license.nil?
      authorize @license, :show?
    end

    typed_parameters transform: true do
      options strict: true

      on :update do
        param :data, type: :hash do
          param :type, type: :string, inclusion: %w[user users]
          param :id, type: :string
        end
      end
    end
  end
end

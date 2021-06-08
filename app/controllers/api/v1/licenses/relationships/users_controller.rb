# frozen_string_literal: true

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
            pointer: "/data/relationships/user"
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
      @license = FindByAliasService.new(current_account.licenses, params[:license_id], aliases: :key).call
      authorize @license, :show?

      Keygen::Store::Request.store[:current_resource] = @license
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

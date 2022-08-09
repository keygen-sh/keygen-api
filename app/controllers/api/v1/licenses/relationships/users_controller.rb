# frozen_string_literal: true

module Api::V1::Licenses::Relationships
  class UsersController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_license

    def show
      user = license.user
      authorize! user

      render jsonapi: user
    end

    def update
      authorize! license, license.user

      license.update!(user_id: user_params[:id])

      BroadcastEventService.call(
        event: 'license.user.updated',
        account: current_account,
        resource: license,
      )

      render jsonapi: license
    end

    private

    attr_reader :license

    def set_license
      scoped_licenses = policy_scope(current_account.licenses)

      @license = FindByAliasService.call(scope: scoped_licenses, identifier: params[:license_id], aliases: :key)

      Current.resource = license
    end

    typed_parameters format: :jsonapi do
      options strict: true

      on :update do
        param :data, type: :hash, allow_nil: true do
          param :type, type: :string, inclusion: %w[user users]
          param :id, type: :string
        end
      end
    end
  end
end

# frozen_string_literal: true

module Api::V1::Licenses::Relationships
  class UsersController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_license

    authorize :license

    def index
      users = apply_pagination(authorized_scope(apply_scopes(license.users)).preload(:any_active_licenses, role: :permissions))
      authorize! users,
        with: Licenses::UserPolicy

      render jsonapi: users
    end

    def show
      user = FindByAliasService.call(license.users, id: params[:id], aliases: :email)
      authorize! user,
        with: Licenses::UserPolicy

      render jsonapi: user
    end


    typed_params {
      format :jsonapi

      param :data, type: :array, length: { minimum: 1, maximum: 100 } do
        items type: :hash do
          param :type, type: :string, inclusion: { in: %w[user users] }
          param :id, type: :uuid, as: :user_id
        end
      end
    }
    def attach
      users = current_account.users.where(id: user_ids)
      authorize! users,
        with: Licenses::UserPolicy

      attached = license.transaction do
        license.license_users.create!(
          user_ids.map {{ user_id: it }},
        )
      end

      BroadcastEventService.call(
        event: 'license.users.attached',
        account: current_account,
        resource: attached,
      )

      render jsonapi: attached
    end

    typed_params {
      format :jsonapi

      param :data, type: :array, length: { minimum: 1, maximum: 100 } do
        items type: :hash do
          param :type, type: :string, inclusion: { in: %w[user users] }
          param :id, type: :uuid, as: :user_id
        end
      end
    }
    def detach
      users = current_account.users.where(id: user_ids)
      authorize! users,
        with: Licenses::UserPolicy

      # Block owner from being detached. This request wouldn't detach the owner, but
      # since non-existing license user IDs are currently noops, responding with a
      # 2xx status code is confusing for the end-user, so we're going to error
      # out early for a better DX.
      if license.owner_id? && user_ids.include?(license.owner_id)
        forbidden_user_id = license.owner_id
        forbidden_idx     = user_ids.find_index(forbidden_user_id)

        return render_forbidden(
          detail: "cannot detach user '#{forbidden_user_id}' (user is attached through owner)",
          source: {
            pointer: "/data/#{forbidden_idx}",
          },
        )
      end

      # Ensure all users exist. Again, non-existing license users would be
      # a noop, but responding with a 2xx status code is a confusing DX.
      license_users = license.license_users.where(user_id: user_ids)

      unless license_users.size == user_ids.size
        license_user_ids = license_users.pluck(:user_id)
        invalid_user_ids = user_ids - license_user_ids
        invalid_user_id  = invalid_user_ids.first
        invalid_idx      = user_ids.find_index(invalid_user_id)

        return render_unprocessable_entity(
          detail: "cannot detach user '#{invalid_user_id}' (user is not attached)",
          source: {
            pointer: "/data/#{invalid_idx}",
          },
        )
      end

      detached = license.transaction do
        license.license_users.destroy(license_users)
      end

      BroadcastEventService.call(
        event: 'license.users.detached',
        account: current_account,
        resource: detached,
      )
    end

    private

    attr_reader :license

    def user_ids = user_params.pluck(:user_id)

    def set_license
      scoped_licenses = authorized_scope(current_account.licenses)

      @license = FindByAliasService.call(scoped_licenses, id: params[:license_id], aliases: :key)

      Current.resource = license
    end
  end
end

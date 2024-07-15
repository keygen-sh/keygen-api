# frozen_string_literal: true

module Api::V1::Releases::Relationships
  class EntitlementsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate!
    before_action :set_release

    authorize :release

    def index
      entitlements = apply_pagination(authorized_scope(apply_scopes(release.entitlements), with: Releases::EntitlementPolicy))
      authorize! entitlements,
        with: Releases::EntitlementPolicy

      render jsonapi: entitlements
    end

    def show
      entitlement = release.entitlements.find(params[:id])
      authorize! entitlement,
        with: Releases::EntitlementPolicy

      render jsonapi: entitlement
    end

    private

    attr_reader :release

    def set_release
      scoped_releases = authorized_scope(current_account.releases)

      @release = FindByAliasService.call(scoped_releases, id: params[:release_id], aliases: %i[version tag])

      Current.resource = release
    end
  end
end

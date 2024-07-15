# frozen_string_literal: true

module Api::V1::Releases::Relationships
  class ReleasePackagesController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate!, except: %i[show]
    before_action :authenticate, only: %i[show]
    before_action :set_release

    authorize :release

    def show
      package = release.package
      authorize! package,
        with: Releases::ReleasePackagePolicy

      render jsonapi: package
    end

    typed_params {
      format :jsonapi

      param :data, type: :hash, allow_nil: true do
        param :type, type: :string, inclusion: { in: %w[package packages] }
        param :id, type: :uuid
      end
    }
    def update
      package = current_account.release_packages.find_by(id: release_package_params[:id])
      authorize! package,
        with: Releases::ReleasePackagePolicy

      release.update!(
        package:,
      )

      BroadcastEventService.call(
        event: 'release.package.updated',
        account: current_account,
        resource: release,
      )

      render jsonapi: package
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

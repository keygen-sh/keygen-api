# frozen_string_literal: true

module Api::V1::ReleaseEngines
  class Electron::UpgradesController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token
    before_action :set_package, only: %i[show]

    typed_query {
      param :constraint, type: :string, optional: true
      param :channel, type: :string, optional: true
    }
    def show
      authorize! package

      platform = params[:platform]
      arch     = params[:arch]

      releases = authorized_scope(package.releases)
      release  = releases.find_by!(version: params[:version])
      authorize! release, to: :upgrade?

      kwargs  = upgrade_query.slice(:constraint, :channel)
      upgrade = release.upgrade!(**kwargs)
      authorize! upgrade

      artifacts = authorized_scope(upgrade.artifacts)
      artifact  = artifacts.joins(:platform, :arch, :filetype)
                           .where.not(filetype: { key: %w[sig] })
                           .reorder(
                             # NOTE(ezekg) Prioritize artifact formats for Electron:
                             #
                             #   macOS: .zip takes precedence (required by Squirrel.Mac)
                             #   Windows: .exe for NSIS/Squirrel.Windows, .nupkg for legacy
                             #   MSIX: .appx/.msix files
                             #
                             Arel.sql(<<~SQL.squish)
                               release_artifacts.filename ILIKE '%.zip' DESC,
                               release_artifacts.filename ILIKE '%.exe' DESC,
                               release_artifacts.filename ILIKE '%.nupkg' DESC,
                               release_artifacts.filename ILIKE '%.appx' DESC,
                               release_artifacts.filename ILIKE '%.msix' DESC,
                               release_artifacts.created_at DESC
                             SQL
                           )
                           .find_by!(
                             platform: { key: platform },
                             arch: { key: arch },
                           )
      authorize! artifact

      BroadcastEventService.call(
        event: 'release.upgraded',
        account: current_account,
        resource: upgrade,
        meta: {
          current: release.version,
          next: upgrade.version,
        },
      )

      # See: https://www.electronjs.org/docs/latest/tutorial/updates
      render json: {
        url: vanity_v1_account_release_artifact_url(artifact.account, artifact, filename: artifact.filename, host: request.host),
        name: upgrade.version,
        notes: upgrade.description,
        pub_date: upgrade.created_at.rfc3339(3),
      }
    rescue ActiveRecord::RecordNotFound
      render_no_content
    end

    private

    attr_reader :package

    def set_package
      @package = Current.resource = FindByAliasService.call(
        authorized_scope(current_account.release_packages.electron),
        id: params[:package],
        aliases: :key,
      )
    end
  end
end

# frozen_string_literal: true

module Api::V1::ReleaseEngines
  class Tauri::UpgradesController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token
    before_action :set_package, only: %i[show]

    typed_query {
      param :constraint, type: :string, optional: true
      param :channel, type: :string, optional: true
      param :platform, type: :string
      param :arch, type: :string
      param :version, type: :string
    }
    def show
      authorize! package

      upgrade_query => platform:, arch:, version:

      releases = authorized_scope(package.releases)
      release  = releases.find_by!(version:)
      authorize! release, to: :upgrade?

      kwargs  = upgrade_query.slice(:constraint, :channel)
      upgrade = release.upgrade!(**kwargs)
      authorize! upgrade

      artifacts = authorized_scope(upgrade.artifacts)
      artifact  = artifacts.joins(:platform, :arch, :filetype)
                           .reorder(
                             # NOTE(ezekg) Order so that NSIS always takes precedence
                             #             over deprecated MSI on conflict.
                             Arel.sql(<<~SQL.squish)
                               release_artifacts.filename ILIKE '%.nsis.zip' DESC,
                               release_artifacts.created_at DESC
                             SQL
                           )
                           .find_by!(
                             filetype: { key: %w[gz zip] },
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

      # See: https://tauri.app/v1/guides/distribution/updater
      render json: {
        url: vanity_v1_account_release_artifact_url(artifact.account, artifact, filename: artifact.filename),
        signature: artifact.signature,
        version: upgrade.version,
        pub_date: upgrade.created_at.rfc3339(3),
        notes: upgrade.description,
      }
    rescue ActiveRecord::RecordNotFound
      render_no_content
    end

    private

    attr_reader :package

    def set_package
      Current.resource = @package = FindByAliasService.call(
        authorized_scope(current_account.release_packages.tauri),
        id: params[:package],
        aliases: :key,
      )
    end
  end
end

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
    }
    def show
      authorize! package

      releases = authorized_scope(package.releases)
      release  = releases.find_by!(version: params[:current_version])
      authorize! release,
        to: :upgrade?

      kwargs  = upgrade_query.slice(:constraint, :channel)
      upgrade = release.upgrade!(**kwargs)
      authorize! upgrade

      artifact = upgrade.artifacts.joins(:platform, :arch, :filetype)
                                  .reorder(filename: :desc) # so that NSIS takes precedence over MSI on conflict
                                  .find_by!(
                                    platform: { key: params[:target] },
                                    arch: { key: params[:arch] },
                                    filetype: { key: %w[gz zip] },
                                  )
      authorize! artifact

      # See: https://tauri.app/v1/guides/distribution/updater
      render json: {
        url: vanity_v1_account_release_artifact_url(artifact.account, artifact, filename: artifact.filename),
        signature: artifact.signature,
        version: upgrade.version,
        pub_date: upgrade.created_at.iso8601(3),
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

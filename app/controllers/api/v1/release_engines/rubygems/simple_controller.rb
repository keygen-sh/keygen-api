# frozen_string_literal: true

module Api::V1::ReleaseEngines
  class Rubygems::SimpleController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token
    before_action :set_gem_package, only: %i[show]

    typed_query do
      param :constraint, type: :string, optional: true
      param :version, type: :string
    end

    def show
      authorize! gem_package

      version = params[:version]
      constraint = params[:constraint]

      # Fetch releases and find the one that matches the version and constraint
      releases = authorized_scope(gem_package.releases)
      release = find_compatible_release(releases, version, constraint)
      authorize! release

      # Fetch artifacts
      artifacts = authorized_scope(release.artifacts)
      artifact = artifacts.joins(:filetype).where(release_filetypes: { key: 'gem' }).first
      authorize! artifact

      # Render JSON response
      render json: {
        url: vanity_v1_account_release_artifact_url(artifact.account, artifact, filename: artifact.filename),
        version: release.version,
        pub_date: release.created_at.rfc3339(3),
        notes: release.description,
      }
    rescue ActiveRecord::RecordNotFound
      # Handle missing gem package or release gracefully
      render_no_content
    end

    private

    attr_reader :gem_package

    # Fetch the gem package based on the alias (e.g., the package name)
    def set_gem_package
      Current.resource = @gem_package = FindByAliasService.call(
        authorized_scope(current_account.release_packages.rubygems),
        id: params[:package],
        aliases: :key,
      )
    rescue Keygen::Error::NotFoundError
      skip_verify_authorized!

      # Redirect to Rubygems.org if the gem package is not found in the current account
      url = URI.parse("https://rubygems.org/gems")
      pkg = CGI.escape(params[:package])

      url.path += "/#{pkg}"

      redirect_to url.to_s, status: :temporary_redirect, allow_other_host: true
    end

    # Finds the most compatible release based on the version and constraint
    def find_compatible_release(releases, version, constraint)
      if constraint.present?
        # If a constraint is provided (e.g., "~> 2.0"), find the best match
        releases.where('version ~ ?', constraint).find_by!(version: version)
      else
        releases.find_by!(version: version)
      end
    end
  end
end

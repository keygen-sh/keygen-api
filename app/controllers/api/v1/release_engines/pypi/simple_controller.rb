# frozen_string_literal: true

module Api::V1::ReleaseEngines
  class Pypi::SimpleController < Api::V1::BaseController
    include Rendering::HTML

    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token
    before_action :set_package, only: %i[show]

    def index
      packages = authorized_scope(apply_scopes(current_account.release_packages.pypi))
      authorize! packages

      render 'api/v1/release_engines/pypi/simple/index',
        layout: 'layouts/simple',
        locals: {
          account: current_account,
          packages:,
        }
    end

    def show
      authorize! package

      artifacts = package.artifacts.order_by_version.preload(release: %i[product entitlements constraints])
      authorize! artifacts,
        to: :index?

      render 'api/v1/release_engines/pypi/simple/show',
        layout: 'layouts/simple',
        locals: {
          account: current_account,
          package:,
          artifacts:,
        }
    end

    private

    attr_reader :package

    def set_package
      @package = Current.resource = FindByAliasService.call(
        authorized_scope(current_account.release_packages.pypi),
        id: params[:package],
        aliases: :key,
      )
    rescue Keygen::Error::NotFoundError
      skip_verify_authorized!

      # NOTE(ezekg) Redirect to PyPI when package is not found, to play nicely with PyPI
      #             not supporting a per-package index. This resolves a security attack
      #             vector where when using --extra-index-url=<keygen>, PyPI could take
      #             precedence over Keygen, pulling a malicious package using the same
      #             name as the requested Keygen package. To resolve this, we recommend
      #             users to set --index-url=<keygen>, and we'll redirect non-existent
      #             packages to PyPI for fulfillment.
      #
      # TODO(ezekg) Make this configurable?
      url = URI.parse("https://pypi.org/simple")
      pkg = CGI.escape(params[:package])

      url.path += "/#{pkg}"

      redirect_to url.to_s, status: :temporary_redirect,
                            allow_other_host: true
    end
  end
end

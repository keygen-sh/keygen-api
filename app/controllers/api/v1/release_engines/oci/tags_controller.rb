# frozen_string_literal: true

module Api::V1::ReleaseEngines
  class Oci::TagsController < Api::V1::BaseController
    before_action :require_ee!
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token
    before_action :set_package

    def index
      authorize! package, to: :show?

      releases = authorized_scope(package.releases).preload(:product, :constraints, :entitlements)
      authorize! releases

      tags = releases.where.not(tag: nil)
                     .reorder(tag: :asc)
                     .pluck(:tag)

      render json: {
        name: package.key,
        tags:,
      }
    rescue ActionPolicy::Unauthorized
      # FIXME(ezekg) docker expects a 401 Unauthorized response with an WWW-Authenticate
      #              challenge, so unfortunately, we can't return a 404 here like we
      #              usually do for unauthorized requests (so as not to leak data).
      if current_bearer.nil?
        render_unauthorized(code: 'UNAUTHORIZED')
      else
        render_forbidden(code: 'DENIED')
      end
    end

    private

    attr_reader :package

    def require_ee! = super(entitlements: %i[oci_engine])

    def set_package
      # NOTE(ezekg) see above comment i.r.t. docker authentication on why we're
      #             skipping authorized_scope here
      scoped_packages = current_account.release_packages.oci

      @package = Current.resource = FindByAliasService.call(
        scoped_packages,
        id: params[:package],
        aliases: :key,
      )
    end
  end
end

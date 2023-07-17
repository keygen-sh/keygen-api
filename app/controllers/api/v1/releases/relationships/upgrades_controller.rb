# frozen_string_literal: true

module Api::V1::Releases::Relationships
  class UpgradesController < Api::V1::BaseController
    has_scope(:product) { |c, s, v| s.for_product(v) }
    has_scope(:package) { |c, s, v| s.for_package(v) }

    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token
    before_action :set_release

    typed_query {
      param :constraint, type: :string, optional: true
      param :channel, type: :string, optional: true
    }
    def show
      authorize! release,
        to: :upgrade?

      kwargs  = upgrade_query.slice(:constraint, :channel)
      upgrade = release.upgrade!(**kwargs)
      authorize! upgrade

      meta = {
        current: release.version,
        next: upgrade.version,
      }

      BroadcastEventService.call(
        event: 'release.upgraded',
        account: current_account,
        resource: upgrade,
        meta:,
      )

      render jsonapi: upgrade, meta:
    rescue Semverse::InvalidConstraintFormat
      render_bad_request detail: 'invalid constraint format',
                         code: :CONSTRAINT_INVALID,
                         source: {
                           parameter: :constraint,
                         }
    end

    private

    attr_reader :release

    def set_release
      scoped_releases = authorized_scope(apply_scopes(current_account.releases))

      @release = FindByAliasService.call(
        scoped_releases,
        id: params[:release_id],
        aliases: %i[version tag],
      )

      Current.resource = release
    end
  end
end

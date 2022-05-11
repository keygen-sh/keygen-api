# frozen_string_literal: true

module Api::V1::Releases::Relationships
  class UpgradesController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token
    before_action :set_release

    def show
      authorize release, :download?

      upgrade = release.upgrade!(constraint: upgrade_query[:constraint])
      authorize upgrade, :download?

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
    rescue Semverse::InvalidConstraintFormat => e
      render_bad_request detail: 'invalid constraint format',
                         code: :CONSTRAINT_INVALID,
                         source: {
                           parameter: :constraint,
                         }
    end

    private

    attr_reader :release

    def set_release
      scoped_releases = policy_scope(current_account.releases)

      @release = FindByAliasService.call(
        scope: scoped_releases,
        identifier: params[:release_id],
        aliases: %i[version tag],
      )

      Current.resource = release
    end

    typed_query do
      on :show do
        query :constraint, type: :string, optional: true
      end
    end
  end
end

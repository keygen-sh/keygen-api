# frozen_string_literal: true

module Api::V1::Products::Relationships::Releases::Actions
  class UpgradesController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token
    before_action :set_product
    before_action :set_release

    def upgrade
      authorize release

      upgrade = release.upgrade!(constraint: upgrade_query[:constraint])
      authorize upgrade

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

      render jsonapi: upgrade, meta:, status: :see_other, location: v1_account_release_path(upgrade.account_id, upgrade)
    rescue Semverse::InvalidConstraintFormat => e
      render_bad_request detail: 'invalid constraint format', code: :CONSTRAINT_INVALID, source: { parameter: :constraint }
    rescue Pundit::NotDefinedError
      render_no_content
    end

    private

    attr_reader :product,
                :release

    def set_product
      @product = current_account.products.find params[:product_id]
    end

    def set_release
      scoped_releases = policy_scope(product.releases)

      @release = FindByAliasService.call(
        scope: scoped_releases,
        identifier: params[:id],
        aliases: :version,
      )

      Current.resource = release
    end

    typed_query do
      on :upgrade do
        query :constraint, type: :string, optional: true
      end
    end
  end
end

# frozen_string_literal: true

module Api::V1::Licenses::Actions
  class PermitsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_license

    def check_in
      authorize! license

      if !license.policy.requires_check_in?
        render_unprocessable_entity detail: 'cannot be checked in because the policy does not require it'
      elsif license.check_in!
        BroadcastEventService.call(
          event: 'license.checked-in',
          account: current_account,
          resource: license,
        )

        render jsonapi: license
      else
        render_unprocessable_resource license
      end
    end

    def renew
      authorize! license

      if license.policy.duration.nil?
        render_unprocessable_entity detail: 'cannot be renewed because the policy does not have a duration'
      elsif license.renew!
        BroadcastEventService.call(
          event: 'license.renewed',
          account: current_account,
          resource: license,
        )

        render jsonapi: license
      else
        render_unprocessable_resource license
      end
    end

    def revoke
      authorize! license

      BroadcastEventService.call(
        event: 'license.revoked',
        account: current_account,
        resource: license,
      )

      license.destroy
    end

    def suspend
      authorize! license

      if license.suspended?
        render_unprocessable_entity(
          source: { pointer: '/data/attributes/suspended' },
          detail: 'is already suspended',
        )
      elsif license.suspend!
        BroadcastEventService.call(
          event: 'license.suspended',
          account: current_account,
          resource: license,
        )

        render jsonapi: license
      else
        render_unprocessable_resource license
      end
    end

    def reinstate
      authorize! license

      if !license.suspended?
        render_unprocessable_entity(
          source: { pointer: '/data/attributes/suspended' },
          detail: 'is not suspended',
        )
      elsif license.reinstate!
        BroadcastEventService.call(
          event: 'license.reinstated',
          account: current_account,
          resource: license,
        )

        render jsonapi: license
      else
        render_unprocessable_resource license
      end
    end

    private

    attr_reader :license

    def set_license
      scoped_licenses = authorized_scope(current_account.licenses)

      @license = FindByAliasService.call(scoped_licenses, id: params[:id], aliases: :key)

      Current.resource = license
    end
  end
end

# frozen_string_literal: true

module Api::V1::Licenses::Actions
  class PermitsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_license

    # POST /licenses/1/check-in
    def check_in
      authorize @license

      if !@license.policy.requires_check_in?
        render_unprocessable_entity detail: "cannot be checked in because the policy does not require it"
      elsif @license.check_in!
        BroadcastEventService.call(
          event: "license.checked-in",
          account: current_account,
          resource: @license
        )

        render jsonapi: @license
      else
        render_unprocessable_resource @license
      end
    end

    # POST /licenses/1/renew
    def renew
      authorize @license

      if @license.policy.duration.nil?
        render_unprocessable_entity({
          detail: "cannot be renewed because it does not expire",
          source: {
            pointer: "/data/attributes/expiry"
          }
        })
      elsif @license.renew!
        BroadcastEventService.call(
          event: "license.renewed",
          account: current_account,
          resource: @license
        )

        render jsonapi: @license
      else
        render_unprocessable_resource @license
      end
    end

    # DELETE /licenses/1/revoke
    def revoke
      authorize @license

      BroadcastEventService.call(
        event: "license.revoked",
        account: current_account,
        resource: @license
      )

      @license.destroy_async
    end

    # POST /licenses/1/suspend
    def suspend
      authorize @license

      if @license.suspended?
        render_unprocessable_entity({
          detail: "is already suspended",
          source: {
            pointer: "/data/attributes/suspended"
          }
        })
      elsif @license.suspend!
        BroadcastEventService.call(
          event: "license.suspended",
          account: current_account,
          resource: @license
        )

        render jsonapi: @license
      else
        render_unprocessable_resource @license
      end
    end

    # POST /licenses/1/reinstate
    def reinstate
      authorize @license

      if !@license.suspended?
        render_unprocessable_entity({
          detail: "is not suspended",
          source: {
            pointer: "/data/attributes/suspended"
          }
        })
      elsif @license.reinstate!
        BroadcastEventService.call(
          event: "license.reinstated",
          account: current_account,
          resource: @license
        )

        render jsonapi: @license
      else
        render_unprocessable_resource @license
      end
    end

    private

    def set_license
      @license = FindByAliasService.call(scope: current_account.licenses, identifier: params[:id], aliases: :key)

      Current.resource = @license
    end
  end
end

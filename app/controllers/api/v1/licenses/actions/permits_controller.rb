module Api::V1::Licenses::Actions
  class PermitsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_license

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
      elsif @license.update(expiry: @license.expiry + @license.policy.duration)
        CreateWebhookEventService.new(
          event: "license.renewed",
          account: current_account,
          resource: @license
        ).execute

        render jsonapi: @license
      else
        render_unprocessable_resource @license
      end
    end

    # DELETE /licenses/1/revoke
    def revoke
      authorize @license

      CreateWebhookEventService.new(
        event: "license.revoked",
        account: current_account,
        resource: @license
      ).execute

      @license.destroy
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
      elsif @license.update(suspended: true)
        CreateWebhookEventService.new(
          event: "license.suspended",
          account: current_account,
          resource: @license
        ).execute

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
      elsif @license.update(suspended: false)
        CreateWebhookEventService.new(
          event: "license.reinstated",
          account: current_account,
          resource: @license
        ).execute

        render jsonapi: @license
      else
        render_unprocessable_resource @license
      end
    end

    private

    def set_license
      @license = current_account.licenses.find params[:id]
    end
  end
end

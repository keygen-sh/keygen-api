module Api::V1::Licenses::Actions
  class UsesController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_license

    # POST /licenses/1/increment-usage
    def increment
      authorize @license

      @license.increment :uses

      if @license.save
        CreateWebhookEventService.new(
          event: "license.usage.incremented",
          account: current_account,
          resource: @license
        ).execute

        render jsonapi: @license
      else
        render_unprocessable_resource @license
      end
    end

    # POST /licenses/1/decrement-usage
    def decrement
      authorize @license

      @license.decrement :uses

      if @license.save
        CreateWebhookEventService.new(
          event: "license.usage.decremented",
          account: current_account,
          resource: @license
        ).execute

        render jsonapi: @license
      else
        render_unprocessable_resource @license
      end
    end

    # POST /licenses/1/reset-usage
    def reset
      authorize @license

      if @license.update(uses: 0)
        CreateWebhookEventService.new(
          event: "license.usage.reset",
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
      # FIXME(ezekg) This allows the license to be looked up by ID or
      #              key, but this is pretty messy.
      id = params[:id] if params[:id] =~ UUID_REGEX # Only include when it's a UUID (else pg throws an err)
      key = params[:id]

      @license = current_account.licenses.where("id = ? OR key = ?", id, key).first
      raise ActiveRecord::RecordNotFound if @license.nil?
    end
  end
end

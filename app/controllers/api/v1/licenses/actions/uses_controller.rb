# frozen_string_literal: true

module Api::V1::Licenses::Actions
  class UsesController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_license

    # POST /licenses/1/increment-usage
    def increment
      authorize @license

      @license.with_lock 'FOR UPDATE NOWAIT' do
        @license.increment :uses, increment_param
        @license.save!
      end

      CreateWebhookEventService.new(
        event: "license.usage.incremented",
        account: current_account,
        resource: @license
      ).execute

      render jsonapi: @license
    rescue ActiveRecord::RecordNotSaved,
           ActiveRecord::RecordInvalid
      render_unprocessable_resource @license
    rescue ActiveRecord::StaleObjectError,
           ActiveRecord::StatementInvalid # Thrown when update is attempted on locked row i.e. from FOR UPDATE NOWAIT
      render_conflict detail: "failed to increment due to another conflicting update",
        source: { pointer: "/data/attributes/uses" }
    rescue ActiveModel::RangeError
      render_bad_request detail: "integer is too large", source: {
        pointer: "/meta/increment" }
    end

    # POST /licenses/1/decrement-usage
    def decrement
      authorize @license

      @license.with_lock 'FOR UPDATE NOWAIT' do
        @license.decrement :uses, decrement_param
        @license.save!
      end

      CreateWebhookEventService.new(
        event: "license.usage.decremented",
        account: current_account,
        resource: @license
      ).execute

      render jsonapi: @license
    rescue ActiveRecord::RecordNotSaved,
           ActiveRecord::RecordInvalid
      render_unprocessable_resource @license
    rescue ActiveRecord::StaleObjectError,
           ActiveRecord::StatementInvalid
      render_conflict detail: "failed to increment due to another conflicting update",
        source: { pointer: "/data/attributes/uses" }
    rescue ActiveModel::RangeError
      render_bad_request detail: "integer is too large", source: {
        pointer: "/meta/decrement" }
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
      @license = current_account.licenses.find params[:id]
    end

    def increment_param
      use_params.dig(:meta, :increment) || 1
    end

    def decrement_param
      use_params.dig(:meta, :decrement) || 1
    end

    typed_parameters do
      options strict: true

      on :increment do
        param :meta, type: :hash, optional: true do
          param :increment, type: :integer, optional: true
        end
      end

      on :decrement do
        param :meta, type: :hash, optional: true do
          param :decrement, type: :integer, optional: true
        end
      end
    end
  end
end

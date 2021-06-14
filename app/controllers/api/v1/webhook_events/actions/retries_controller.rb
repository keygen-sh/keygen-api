# frozen_string_literal: true

module Api::V1::WebhookEvents::Actions
  class RetriesController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_event

    # POST /webhook-events/1/retry
    def retry
      authorize @event

      if event = RetryWebhookEventService.call(event: @event)
        render jsonapi: event, status: :created, location: v1_account_webhook_event_url(event.account, event)
      else
        render_unprocessable_entity detail: "webhook event failed to retry"
      end
    end

    private

    def set_event
      @event = current_account.webhook_events.find params[:id]
    end
  end
end

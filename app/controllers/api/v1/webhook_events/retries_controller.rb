module Api::V1::WebhookEvents
  class RetriesController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :authenticate_with_token!
    before_action :set_event

    # POST /webhook-events/1/retry
    def retry
      authorize @event

      if event = RetryWebhookEventService.new(event: @event).execute
        render json: event, status: :created, location: v1_account_webhook_event_url(event.account, event)
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

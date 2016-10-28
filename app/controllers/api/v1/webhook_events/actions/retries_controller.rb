module Api::V1::WebhookEvents::Actions
  class RetriesController < Api::V1::BaseController
    before_action :scope_by_subdomain!
    before_action :authenticate_with_token!
    before_action :set_event

    # POST /webhook-events/1/actions/retry
    def retry
      render_not_found and return unless @event

      authorize @event

      if retried_event = RetryWebhookEventService.new(event: @event).execute
        render json: retried_event
      else
        render_unprocessable_entity detail: "webhook event failed to retry"
      end
    end

    private

    def set_event
      @event = current_account.webhook_events.find_by_hashid params[:webhook_event_id]
    end
  end
end

# frozen_string_literal: true

module Api::V1::WebhookEvents::Actions
  class RetriesController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate!
    before_action :set_event

    def retry
      authorize! event

      if e = RetryWebhookEventService.call(event:)
        render jsonapi: e, status: :created, location: v1_account_webhook_event_url(e.account, e)
      else
        render_unprocessable_entity detail: 'webhook event failed to retry'
      end
    end

    private

    attr_reader :event

    def set_event
      scoped_events = authorized_scope(current_account.webhook_events)

      @event = scoped_events.find(params[:id])

      Current.resource = event
    end
  end
end

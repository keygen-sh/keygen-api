# frozen_string_literal: true

module Api::V1
  class WebhookEventsController < Api::V1::BaseController
    has_scope(:events, type: :array) { |c, s, v| s.with_events(v) }

    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_event, only: [:show, :destroy]

    def index
      events = apply_pagination(authorized_scope(apply_scopes(current_account.webhook_events)).preload(:event_type, :product))
      authorize! events

      render jsonapi: events
    end

    def show
      authorize! event

      render jsonapi: event
    end

    def destroy
      authorize! event

      event.destroy
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

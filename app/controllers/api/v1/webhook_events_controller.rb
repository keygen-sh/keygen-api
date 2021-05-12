# frozen_string_literal: true

module Api::V1
  class WebhookEventsController < Api::V1::BaseController
    has_scope :events, type: :array

    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_event, only: [:show, :destroy]

    # GET /webhook-events
    def index
      @events = policy_scope apply_scopes(current_account.webhook_events.without_blobs.preload(:event_type))
      authorize @events

      render jsonapi: @events
    end

    # GET /webhook-events/1
    def show
      authorize @event

      render jsonapi: @event
    end

    # DELETE /webhook-events/1
    def destroy
      authorize @event

      @event.destroy_async
    end

    private

    def set_event
      @event = current_account.webhook_events.find params[:id]
    end
  end
end

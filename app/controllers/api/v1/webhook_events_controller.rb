module Api::V1
  class WebhookEventsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :authenticate_with_token!
    before_action :set_event, only: [:show]

    # GET /webhook-events
    def index
      @events = policy_scope apply_scopes(current_account.webhook_events).all
      authorize @events

      render json: @events
    end

    # GET /webhook-events/1
    def show
      render_not_found and return unless @event

      authorize @event

      render json: @event
    end

    private

    def set_event
      @event = current_account.webhook_events.find_by id: params[:id]
    end
  end
end

module Api::V1
  class WebhookEventsController < Api::V1::BaseController
    has_scope :page, type: :hash

    before_action :scope_by_subdomain!
    before_action :authenticate_with_token!
    before_action :set_event, only: [:show]

    # GET /webhook-events
    def index
      @events = policy_scope apply_scopes(@current_account.webhook_events).all
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
      @event = WebhookEvent.find_by_hashid params[:id]
    end
  end
end

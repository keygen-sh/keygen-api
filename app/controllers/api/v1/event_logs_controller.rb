# frozen_string_literal: true

module Api::V1
  class EventLogsController < Api::V1::BaseController
    has_scope(:date, type: :hash, using: [:start, :end], only: :index)
    has_scope(:whodunnit, type: :any) { |c, s, v| s.search_whodunnit(v) }
    has_scope(:resource, type: :any) { |c, s, v| s.search_resource(v) }
    has_scope(:request) { |c, s, v| s.search_request_id(v) }
    has_scope(:event) { |c, s, v| s.for_event_type(v) }

    before_action :require_ee!
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :require_ent_subscription!
    before_action :authenticate_with_token!
    before_action :set_event_log, only: %i[show]

    def index
      authorize! with: EventLogPolicy

      json = Rails.cache.fetch(cache_key, expires_in: 1.minute, race_condition_ttl: 30.seconds) do
        event_logs = apply_pagination(authorized_scope(apply_scopes(current_account.event_logs)).preload(:event_type, :account, :whodunnit, :resource))
        data = Keygen::JSONAPI.render(event_logs)

        data.tap do |d|
          d[:links] = pagination_links(event_logs)
        end
      end

      render json: json
    end

    def show
      authorize! event_log,
        with: EventLogPolicy

      render jsonapi: event_log
    end

    private

    attr_reader :event_log

    def set_event_log
      scoped_logs = authorized_scope(current_account.event_logs)

      @event_log = scoped_logs.find(params[:id])

      Current.resource = event_log
    end

    def cache_key
      [:event_logs, current_account.id, Digest::SHA2.hexdigest(request.query_string), CACHE_KEY_VERSION].join ":"
    end

    def require_ee!
      super(entitlements: %i[event_logs])
    end
  end
end

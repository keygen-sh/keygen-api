# frozen_string_literal: true

module Api::V1
  class EventLogsController < Api::V1::BaseController
    use_clickhouse

    has_scope(:date, type: :hash, using: [:start, :end]) { |c, s, v| s.for_date_range(*v) }
    has_scope(:whodunnit, type: :any) { |c, s, v| s.search_whodunnit(v) }
    has_scope(:resource, type: :any) { |c, s, v| s.search_resource(v) }
    has_scope(:request) { |c, s, v| s.search_request_id(v) }
    has_scope(:event) { |c, s, v| s.for_event_type(v) }
    has_scope(:events, type: :array) { |c, s, v| s.for_event_types(v) }

    before_action :require_ee!
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_event_log, only: %i[show]

    def index
      event_logs = apply_pagination(authorized_scope(apply_scopes(current_account.event_logs.ordered)).preload(:event_type, :account))
      authorize! event_logs

      render jsonapi: event_logs
    end

    def show
      authorize! event_log

      render jsonapi: event_log
    end

    private

    attr_reader :event_log

    def set_event_log
      scoped_event_logs = authorized_scope(current_account.event_logs)

      @event_log = scoped_event_logs.find_by!(id: params[:id])

      Current.resource = event_log
    end

    def require_ee!
      super(entitlements: %i[event_logs])
    end
  end
end

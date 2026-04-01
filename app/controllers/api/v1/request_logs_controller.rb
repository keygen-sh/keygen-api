# frozen_string_literal: true

module Api::V1
  class RequestLogsController < Api::V1::BaseController
    has_scope(:date, type: :hash, using: [:start, :end]) { |c, s, v| s.for_date_range(*v) }
    has_scope(:requestor, type: :any) { |c, s, v| s.search_requestor(v) }
    has_scope(:resource, type: :any) { |c, s, v| s.search_resource(v) }
    has_scope(:ip) { |c, s, v| s.search_ip(v) }
    has_scope(:method) { |c, s, v| s.search_method(v) }
    has_scope(:url) { |c, s, v| s.search_url(v) }
    has_scope(:status) { |c, s, v| s.search_status(v) }

    before_action :require_ee!
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_request_log, only: %i[show]

    def index
      request_logs = apply_pagination(authorized_scope(apply_scopes(current_account.request_logs.ordered.without_blobs)).preload(:account))
      authorize! request_logs

      render jsonapi: request_logs
    end

    def show
      authorize! request_log

      render jsonapi: request_log
    end

    private

    attr_reader :request_log

    def set_request_log
      scoped_request_logs = authorized_scope(current_account.request_logs)

      @request_log = scoped_request_logs.find_by!(id: params[:id])

      Current.resource = request_log
    end

    def require_ee!
      super(entitlements: %i[request_logs])
    end
  end
end

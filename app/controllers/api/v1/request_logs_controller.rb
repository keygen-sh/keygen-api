# frozen_string_literal: true

module Api::V1
  class RequestLogsController < Api::V1::BaseController
    has_scope(:date, type: :hash, using: [:start, :end], only: :index)
    has_scope(:requestor, type: :any) { |c, s, v| s.search_requestor(v) }
    has_scope(:resource, type: :any) { |c, s, v| s.search_resource(v) }
    has_scope(:request) { |c, s, v| s.search_request_id(v) }
    has_scope(:ip) { |c, s, v| s.search_ip(v) }
    has_scope(:method) { |c, s, v| s.search_method(v) }
    has_scope(:url) { |c, s, v| s.search_url(v) }
    has_scope(:status) { |c, s, v| s.search_status(v) }
    has_scope(:event) { |c, s, v| s.for_event_type(v) }

    before_action :require_ee!
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_request_log, only: [:show]

    def index
      authorize! with: RequestLogPolicy

      json = Rails.cache.fetch(cache_key, expires_in: 1.minute, race_condition_ttl: 30.seconds) do
        request_logs = apply_pagination(authorized_scope(apply_scopes(current_account.request_logs)).without_blobs.preload(:account, :requestor, :resource))
        data = Keygen::JSONAPI.render(request_logs)

        data.tap do |d|
          d[:links] = pagination_links(request_logs)
        end
      end

      render json: json
    end

    def show
      authorize! with: RequestLogPolicy

      render jsonapi: request_log
    end

    private

    attr_reader :request_log

    def set_request_log
      scoped_request_logs = authorized_scope(current_account.request_logs)

      @request_log = scoped_request_logs.find(params[:id])

      Current.resource = request_log
    end

    def cache_key
      [:request_logs, current_account.id, Digest::SHA2.hexdigest(request.query_string), CACHE_KEY_VERSION].join ":"
    end

    def require_ee!
      super(entitlements: %i[request_logs])
    end
  end
end

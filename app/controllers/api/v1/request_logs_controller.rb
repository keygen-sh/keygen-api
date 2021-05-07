# frozen_string_literal: true

module Api::V1
  class RequestLogsController < Api::V1::BaseController
    has_scope :date, type: :hash, using: [:start, :end], only: :index
    has_scope :page, type: :hash, using: [:number, :size], default: { number: 1, size: 100 }, only: :index
    has_scope(:requestor, type: :hash, using: [:type, :id]) { |_, s, (t, id)| s.search_requestor(t, id) }
    has_scope(:resource, type: :hash, using: [:type, :id]) { |_, s, (t, id)| s.search_resource(t, id) }
    has_scope(:request) { |_, s, v| s.search_request_id(v) }
    has_scope(:ip) { |_, s, v| s.search_ip(v) }
    has_scope(:method) { |_, s, v| s.search_method(v) }
    has_scope(:url) { |_, s, v| s.search_url(v) }
    has_scope(:status) { |_, s, v| s.search_status(v) }

    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_request_log, only: [:show]

    # GET /request-logs
    def index
      authorize RequestLog

      json = Rails.cache.fetch(cache_key, expires_in: 1.minute, race_condition_ttl: 30.seconds) do
        request_logs = policy_scope apply_scopes(current_account.request_logs.without_blobs )
        data = JSONAPI::Serializable::Renderer.new.render(request_logs, {
          expose: { url_helpers: Rails.application.routes.url_helpers },
          class: {
            Account: SerializableAccount,
            RequestLog: SerializableRequestLog,
            Error: SerializableError
          }
        })

        data.tap do |d|
          d[:links] = pagination_links(request_logs)
        end
      end

      render json: json
    end

    # GET /request-logs/1
    def show
      authorize @request_log

      render jsonapi: @request_log
    end

    private

    def set_request_log
      @request_log = current_account.request_logs.find params[:id]
    end

    def cache_key
      [:logs, current_account.id, Digest::SHA2.hexdigest(request.query_string), CACHE_KEY_VERSION].join ":"
    end
  end
end

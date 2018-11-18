module Api::V1
  class RequestLogsController < Api::V1::BaseController
    has_scope :date, type: :hash, using: [:start, :end], only: :index
    has_scope :page, type: :hash, using: [:number, :size], default: { number: 1, size: 100 }, only: :index

    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_request_log, only: [:show]

    # GET /request-logs
    def index
      authorize RequestLog

      json = Rails.cache.fetch(cache_key, expires_in: 15.minutes) do
        request_logs = policy_scope apply_scopes(current_account.request_logs)
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
      [:logs, current_account.id, request.query_string.parameterize].select(&:present?).join ":"
    end
  end
end

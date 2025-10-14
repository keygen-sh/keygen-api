# frozen_string_literal: true

module RequestLogger
  extend ActiveSupport::Concern

  REQUEST_LOG_IGNORED_ORIGINS   = %w[https://app.keygen.sh https://dist.keygen.sh].freeze
  REQUEST_LOG_IGNORED_HOSTS     = %w[get.keygen.sh bin.keygen.sh].freeze
  REQUEST_LOG_IGNORED_RESOURCES = %w[
    webhook_endpoints
    webhook_events
    request_logs
    event_logs
    accounts
    searches
    metrics
    analytics
    health
    stripe
    plans
  ].freeze

  REQUEST_LOG_REQUEST_HEADERS = %w[
    Accept
    Content-Length
    Content-Type
    Origin
    Host
  ]

  REQUEST_LOG_RESPONSE_HEADERS = %w[
    Content-Length
    Content-Type
    Date
    Digest
    Keygen-Account
    Keygen-Bearer
    Keygen-Date
    Keygen-Digest
    Keygen-Edition
    Keygen-Environment
    Keygen-License
    Keygen-Mode
    Keygen-Signature
    Keygen-Token
    Keygen-Version
  ]

  included do
    prepend_around_action :log_request!

    private

    # FIXME(ezekg) This doesn't log rate limiting and bad request errors caught
    #              by our middleware error wrapper
    #
    def log_request!
      @request_log_start_clock = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      @request_log_start_time  = Time.current

      yield
    ensure
      @request_log_end_clock = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      queue_request_log_worker
    end

    def log_request?
      return false if
        REQUEST_LOG_IGNORED_ORIGINS.include?(request.headers['Origin'])

      return false if
        REQUEST_LOG_IGNORED_HOSTS.include?(request.host)

      controller = request.path_parameters[:controller]
      return false if
        REQUEST_LOG_IGNORED_RESOURCES.any? { controller&.include?(it) }

      Current.account.present?
    end

    def queue_request_log_worker
      return unless
        Keygen.ee? && Keygen.ee { it.entitled?(:request_logs) }

      return unless
        log_request?

      RequestLogWorker2.perform_async(
        'id' => Current.request_id,
        'account_id' => Current.account.id,
        'environment_id' => Current.environment&.id,
        'requestor_type' => Current.bearer&.class&.name,
        'requestor_id' => Current.bearer&.id,
        'resource_type' => Current.resource&.class&.name,
        'resource_id' => Current.resource&.id,
        'created_date' => request_log_request_time.to_date.iso8601,
        'created_at' => request_log_request_time.iso8601(6),
        'user_agent' => request_log_user_agent,
        'ip' => request_log_ip,
        'method' => request_log_method,
        'url' => request_log_url,
        'request_headers' => request_log_request_headers,
        'request_body' => request_log_request_body,
        'response_signature' => request_log_signature,
        'response_headers' => request_log_response_headers,
        'response_body' => request_log_response_body,
        'status' => request_log_status,
        'queue_time' => request_log_request_queue_time,
        'run_time' => request_log_request_run_time,
      )
    rescue => e
      Keygen.logger.exception(e)
    end

    def request_log_request_queue_time = @request_log_start_time.to_f - request_log_request_time.to_f
    def request_log_request_run_time   = (@request_log_end_clock - @request_log_start_clock) * 1_000
    def request_log_request_time
      value = request.env['HTTP_X_REQUEST_START'] || request.env['HTTP_X_QUEUE_START'] # use these when available
      return @request_log_start_time if
        value.nil?

      # remove non-numerics
      value = value.to_s.gsub(/[^0-9]/, '')

      # convert to milliseconds compatible with Time.at()
      ms = "#{value[0, 10]}.#{value[10, 6]}".to_f

      t = Time.at(ms)
      return @request_log_start_time if
        t > @request_log_start_time # sanity check

      t
    rescue => e
      Keygen.logger.exception(e)

      @request_log_start_time # just in case
    end

    def request_log_user_agent
      if request.user_agent.present? && request.user_agent.valid_encoding?
        request.user_agent.encode('ascii', invalid: :replace, undef: :replace)
      else
        nil
      end
    end

    def request_log_ip
      request.remote_ip
    end

    def request_log_method
      request.method
    end

    def request_log_url
      if response.response_code < 500
        request.filtered_path || request.original_fullpath
      else
        request.original_fullpath
      end
    end

    def request_log_request_headers
      headers = REQUEST_LOG_REQUEST_HEADERS.reduce({}) do |hash, header|
        value = request.headers[header]

        hash.merge(header => value)
      end

      headers.compact
    end

    def request_log_request_body
      params = request.filtered_parameters.slice(:meta, :data)
      if params.present?
        params.deep_transform_keys { |k| k.to_s.camelize(:lower) }
              .to_json
      else
        nil
      end
    rescue => e
      Keygen.logger.exception(e)
    end

    def request_log_response_headers
      headers = REQUEST_LOG_RESPONSE_HEADERS.reduce({}) do |hash, header|
        value = response.headers[header]

        hash.merge(header => value)
      end

      headers.compact
    end

    def request_log_response_body
      body = response.body
      return unless
        body.present?

      mime_type, * = Mime::Type.parse(response.content_type.to_s)
      filtered     = case mime_type
                     in symbol: :jsonapi | :json
                       filterer = ActiveSupport::ParameterFilter.new(%i[password digest token secret otp redirect auth])
                       params   = JSON.parse(body)

                       filterer.filter(params).to_json
                     in symbol: :text | :html
                       body
                     in symbol: :binary
                       nil # we don't ever want to store binary
                     else
                       nil
                     end

      filtered
    rescue => e
      Keygen.logger.exception(e)
    end

    def request_log_status
      response.response_code
    end

    def request_log_signature
      response.headers['Keygen-Signature']
    end
  end
end

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

  included do
    prepend_around_action :log_request!

    private

    # FIXME(ezekg) This doesn't log rate limiting and bad request errors caught
    #              by our middleware error wrapper
    #
    def log_request!
      yield
    ensure
      queue_request_log_worker
    end

    def log_request?
      return false if
        REQUEST_LOG_IGNORED_ORIGINS.include?(request.headers['Origin'])

      return false if
        REQUEST_LOG_IGNORED_HOSTS.include?(request.host)

      controller = request.path_parameters[:controller]
      return false if
        REQUEST_LOG_IGNORED_RESOURCES.any? { controller&.include?(_1) }

      Current.account.present?
    end

    def queue_request_log_worker
      return unless
        Keygen.ee? && Keygen.ee { _1.entitled?(:request_logs) }

      return unless
        log_request?

      RequestLogWorker.perform_async(
        Current.account.id,
        Current.bearer&.class&.name,
        Current.bearer&.id,
        Current.resource&.class&.name,
        Current.resource&.id,
        Current.request_id,
        request_log_time,
        request_log_user_agent,
        request_log_method,
        request_log_url,
        request_log_request_body,
        request_log_ip,
        request_log_signature,
        request_log_response_body,
        request_log_status,
        Current.environment&.id,
      )
    rescue => e
      Keygen.logger.exception(e)
    end

    def request_log_time
      Time.current.iso8601(6)
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

    def request_log_response_body
      body = response.body
      return unless
        body.present?

      return body unless
        response.content_type&.include?('json')

      params   = JSON.parse(body)
      filterer = ActiveSupport::ParameterFilter.new(%i[password digest token secret otp redirect])
      filtered = filterer.filter(params)

      filtered.to_json
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

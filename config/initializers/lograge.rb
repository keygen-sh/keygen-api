# frozen_string_literal: true

Rails.application.configure do
  config.lograge.base_controller_class = 'ActionController::API'
  config.lograge.enabled = true

  config.lograge.custom_payload do |controller|
    rate_limit_data = controller.rate_limiting_data || {}
    account_id = controller.current_account&.id
    account_slug = controller.current_account&.slug
    env_id = controller.current_environment&.id
    env_code = controller.current_environment&.code
    bearer_type = controller.current_bearer&.class&.name&.underscore
    bearer_id = controller.current_bearer&.id
    token_id = controller.current_token&.id
    authn = controller.current_http_scheme
    authz = controller.current_bearer&.role&.name
    api_version = controller.current_api_version
    api_revision = Keygen.revision&.first(7)
    req = controller.request
    res = controller.response
    query_params =
      if req.query_string.present?
        filtered_qs = req.send(:filtered_query_string) # private

        "{#{filtered_qs}}"
      else
        nil
      end

    begin
      code =
        if res.status > 399
          body = JSON.parse(res.body) rescue {}
          errs = body.fetch('errors') { [] }

          if errs.any? { |e| e.key?('code') }
            errs.map { |e| e['code'] }.join ','
          else
            nil
          end
        else
          nil
        end
    rescue => e
      Keygen.logger.exception e
    end

    begin
      enc_res =
        if res.status > 399
          Base64.strict_encode64 res.body
        else
          nil
        end
    rescue => e
      Keygen.logger.exception e
    end

    daily_req_limits =
      {}.tap do |req|
        acct = controller.current_account
        next if acct.nil?

        # FIXME(ezekg) Sometimes we get DB connection issues here if the conn
        #              has already been closed, or closed due to an error.
        begin
          req[:req_exceeded] = acct.daily_request_limit_exceeded? || false
          req[:req_count] = acct.daily_request_count || 'N/A'
          req[:req_limit] = acct.daily_request_limit || 'N/A'
        rescue => e
          Keygen.logger.exception e
        end
      end

    rate_limit_logs =
      {}.tap do |log|
        next if rate_limit_data.nil?

        log[:rate_limited] = rate_limit_data[:count].to_i > rate_limit_data[:limit].to_i
        log[:rate_reset] = Time.at(rate_limit_data[:reset]) rescue nil
        log[:rate_window] = rate_limit_data[:window].to_i
        log[:rate_count] = rate_limit_data[:count].to_i
        log[:rate_limit] = rate_limit_data[:limit].to_i
        log[:rate_remaining] = rate_limit_data[:remaining].to_i
      end

    {
      host: req.host,
      request_id: req.request_id,
      api_revision: api_revision || 'N/A',
      api_version: api_version || 'N/A',
      query_params: query_params || 'N/A',
      account_id: account_id || 'N/A',
      account_slug: account_slug || 'N/A',
      env_id: env_id || 'N/A',
      env_code: env_code || 'N/A',
      bearer_type: bearer_type || 'N/A',
      bearer_id: bearer_id || 'N/A',
      token_id: token_id || 'N/A',
      authn: authn || 'N/A',
      authz: authz || 'N/A',
      ip: req.remote_ip,
      user_agent: req.user_agent || 'N/A',
      origin: req.headers['origin'] || 'N/A',
      time: Time.current,
      code: code || 'N/A',
      encoded_response: enc_res || 'N/A',
      **daily_req_limits,
      **rate_limit_logs,
    }
  end
end

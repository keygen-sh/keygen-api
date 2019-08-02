# frozen_string_literal: true

Rails.application.configure do
  config.lograge.base_controller_class = 'ActionController::API'
  config.lograge.enabled = true

  config.lograge.custom_payload do |controller|
    rate_limit_info = controller.rate_limiting_info || {}
    account_id = controller.current_account&.id
    account_slug = controller.current_account&.slug
    bearer_type = controller.current_bearer&.class&.name&.underscore
    bearer_id = controller.current_bearer&.id
    token_id = controller.current_token&.id
    req = controller.request
    res = controller.response
    err =
      if res.status > 399
        Base64.strict_encode64 res.body
      else
        nil
      end

    query_params =
      if req.query_string.present?
        "{#{req.query_string}}"
      else
        'N/A'
      end

    rate_limit_logs =
      {}.tap do |log|
        next if rate_limit_info.nil?

        log[:rate_limited] = rate_limit_info[:count].to_i > rate_limit_info[:limit].to_i
        log[:rate_reset] = Time.at(rate_limit_info[:reset]) rescue nil
        log[:rate_window] = rate_limit_info[:window].to_i
        log[:rate_count] = rate_limit_info[:count].to_i
        log[:rate_limit] = rate_limit_info[:limit].to_i
        log[:rate_remaining] = rate_limit_info[:remaining].to_i
      end

    {
      query_params: query_params,
      account_id: account_id || 'N/A',
      account_slug: account_slug || 'N/A',
      bearer_type: bearer_type || 'N/A',
      bearer_id: bearer_id || 'N/A',
      token_id: token_id || 'N/A',
      ip: req.headers['cf-connecting-ip'] || req.remote_ip,
      user_agent: req.user_agent || 'N/A',
      time: Time.current,
      encoded_response: err || 'N/A',
      **rate_limit_logs,
    }
  end
end
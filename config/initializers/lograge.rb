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

    {
      account_id: account_id || 'N/A',
      account_slug: account_slug || 'N/A',
      bearer_type: bearer_type || 'N/A',
      bearer_id: bearer_id || 'N/A',
      token_id: token_id || 'N/A',
      ip: req.headers['cf-connecting-ip'] || req.remote_ip,
      user_agent: req.user_agent || 'N/A',
      time: Time.current,
      **rate_limit_info,
    }
  end
end
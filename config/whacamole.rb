Whacamole.configure ENV['WHACAMOLE_APP_NAME'] do |config|
  config.api_token = ENV['WHACAMOLE_API_TOKEN']
  config.dynos = %w[web]
  config.restart_threshold = 500
  config.restart_window = 30*60
end

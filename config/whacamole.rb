Whacamole.configure ENV['WHACAMOLE_APP_NAME'] do |config|
  config.api_token = ENV['WHACAMOLE_API_TOKEN']
  config.dynos = %w[web]
  config.restart_threshold = ENV.fetch('WHACAMOLE_RESTART_THRESHOLD') { 500 }.to_i
  config.restart_window = ENV.fetch('WHACAMOLE_RESTART_WINDOW') { 30 * 60 }.to_i
end

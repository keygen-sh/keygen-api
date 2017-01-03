Raygun.setup do |config|
  config.api_key = ENV["RAYGUN_APIKEY"]
  config.filter_parameters = Rails.application.config.filter_parameters
end

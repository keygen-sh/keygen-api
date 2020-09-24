# frozen_string_literal: true

Raygun.setup do |config|
  config.api_key = ENV["RAYGUN_APIKEY"]
  config.affected_user_method = :current_bearer
  config.filter_parameters = Rails.application.config.filter_parameters
end

# frozen_string_literal: true

middleware = Rails.application.config.middleware

middleware.insert_before 0, Rack::Timeout

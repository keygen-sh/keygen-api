# frozen_string_literal: true

module UrlHelper
  include Rails.application.routes.url_helpers

  def default_url_options = Rails.application.default_url_options
end

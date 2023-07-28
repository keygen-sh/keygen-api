# frozen_string_literal: true

module UrlHelper
  extend ActiveSupport::Concern

  include Rails.application.routes.url_helpers

  included do
    def default_url_options = Rails.application.default_url_options
  end
end

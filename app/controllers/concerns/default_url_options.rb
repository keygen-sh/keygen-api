# frozen_string_literal: true

module DefaultUrlOptions
  extend ActiveSupport::Concern

  class_methods do
    # FIXME(ezekg) Why is this needed?
    def default_url_options(...) = Rails.application.default_url_options(...)
  end
end

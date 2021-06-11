# frozen_string_literal: true

class ErrorsController < ApplicationController
  STATUS_CODES = Rack::Utils::HTTP_STATUS_CODES.transform_values { |v| v.encode('utf-8') }

  before_action :validate_accept_and_add_content_type_headers!
  before_action :set_status_code

  def show
    skip_authorization

    self.send "render_#{status_code}"
  end

  private

  attr_accessor :status_code

  def set_status_code
    @status_code = STATUS_CODES[params[:code].to_i || 500].parameterize.underscore
  end
end

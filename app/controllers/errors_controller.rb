# frozen_string_literal: true

class ErrorsController < ApplicationController
  STATUS_CODES = Rack::Utils::HTTP_STATUS_CODES.transform_values { |v| v.encode('utf-8') }

  skip_verify_authorized

  before_action :set_status_code

  def show
    self.send "render_#{status_code}"
  end

  private

  attr_accessor :status_code

  def set_status_code
    @status_code = STATUS_CODES[params[:code].to_i || 500].parameterize.underscore
  end
end

# frozen_string_literal: true

class ErrorsController < ApplicationController
  STATUS_CODES = Rack::Utils::HTTP_STATUS_CODES

  before_action :set_status

  def show
    skip_authorization
    self.send "render_#{@status}"
  end

  private

  def set_status
    @status = STATUS_CODES[params[:code].to_i || 500].parameterize.underscore
  end
end

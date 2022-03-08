# frozen_string_literal: true

module Api::V1
  class BaseController < ApplicationController
    include TypedParameters::ControllerMethods
    include DefaultHeaders
    include RateLimiting
    include CurrentAccountConstraints
    include CurrentAccountScope
    include TokenAuthentication
    include Pagination
  end
end

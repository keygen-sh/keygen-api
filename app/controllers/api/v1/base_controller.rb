# frozen_string_literal: true

module Api::V1
  class BaseController < ApplicationController
    include TypedParameters::ControllerMethods
    include DefaultHeaders
    include RateLimiting
    include CurrentAccountConstraints
    include CurrentAccountScope
    include TokenAuthentication
    include SharedScopes
    include Pagination

    # NOTE(ezekg) Including these at the end so that they're run last
    include RequestCounter
    include RequestLogger
  end
end

# frozen_string_literal: true

module Api::V1
  class BaseController < ApplicationController
    include TypedParameters::ControllerMethods
    include RequireActiveSubscription
    include TokenAuthentication
    include CurrentAccountScope
    include SharedScopes
    include Pagination
    include SignatureHeader
  end
end

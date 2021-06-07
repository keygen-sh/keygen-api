# frozen_string_literal: true

module Api::V1
  class BaseController < ApplicationController
    include TypedParameters::ControllerMethods
    include RequireActiveSubscription
    include CurrentAccountScope
    include TokenAuthentication
    include SharedScopes
    include Pagination
  end
end

# frozen_string_literal: true

module Api::V1
  class BaseController < ApplicationController
    include CurrentAccountConstraints
    include CurrentAccountScope
    include Authentication
    include Authorization
    include Pagination
  end
end

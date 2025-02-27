# frozen_string_literal: true

module Api::V1
  class BaseController < ApplicationController
    include CurrentAccountConstraints
    include CurrentAccountScope
    include CurrentEnvironmentScope
    include Pagination
  end
end

module Api::V1
  class BaseController < ApplicationController
    include ActionController::Serialization
    include SubdomainScope
    include AccessControl

    def render_unauthorized
      render json: { errors: [{ slug: "unauthorized" }] }, status: :unauthorized
    end
  end
end

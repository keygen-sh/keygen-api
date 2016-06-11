class ApplicationController < ActionController::API
  include Pundit

  attr_accessor :current_user

  after_action :verify_authorized

  rescue_from Pundit::NotAuthorizedError, with: :render_forbidden
  rescue_from Pundit::NotDefinedError, with: :render_not_found

  protected

  def render_meta(meta)
    render json: ActiveModelSerializers::KeyTransform.camel_lower(meta: meta).to_json
  end

  def render_forbidden(message = nil, info = {})
    message = nil unless message.is_a? String
    render json: {
      errors: [{
        title: "Access denied",
        detail: message || "You do not have permission to view this resource"
      }.merge(info)]
    }, status: :forbidden
  end

  def render_unauthorized(message = nil, info = {}, realm = "Application")
    self.headers["WWW-Authenticate"] = %(Token realm="#{realm.gsub(/"/, "")}")
    message = nil unless message.is_a? String
    render json: {
      errors: [{
        title: "Unauthenticated",
        detail: message || "You must be authenticated to view this resource"
      }.merge(info)]
    }, status: :unauthorized
  end

  def render_unprocessable_entity(message = nil, info = {})
    message = nil unless message.is_a? String
    render json: {
      errors: [{
        title: "Unprocessable entity",
        detail: message || "The request could not be completed on this resouce"
      }.merge(info)]
    }, status: :unprocessable_entity
  end

  def render_not_found(message = nil, info = {})
    message = nil unless message.is_a? String
    render json: {
      errors: [{
        title: "Not found",
        detail: message || "The requested resource was not found"
      }.merge(info)]
    }, status: :not_found
  end
end

class ApplicationController < ActionController::Base
  include Pundit

  attr_accessor :current_user

  after_action :verify_authorized

  rescue_from ActionController::UnpermittedParameters, with: -> (err) { render_bad_request detail: err.message }
  rescue_from ActionController::ParameterMissing, with: -> (err) { render_bad_request detail: err.message }

  rescue_from Pundit::NotAuthorizedError, with: :render_forbidden
  rescue_from Pundit::NotDefinedError, with: :render_not_found

  def index
    skip_authorization

    render template: "/templates/index.html.haml", layout: false
  end

  protected

  def render_meta(meta)
    render json: ActiveModelSerializers::KeyTransform.camel_lower(meta: meta).to_json
  end

  def render_forbidden(opts = {})
    opts = {} unless opts.is_a? Hash
    render json: {
      errors: [{
        title: "Access denied",
        detail: "You do not have permission to view this resource"
      }.merge(opts)]
    }, status: :forbidden
  end

  def render_unauthorized(opts = {}, auth = "Token")
    self.headers["WWW-Authenticate"] = %(#{auth} realm="Application")
    opts = {} unless opts.is_a? Hash
    render json: {
      errors: [{
        title: "Unauthorized",
        detail: "You must be authenticated to view this resource"
      }.merge(opts)]
    }, status: :unauthorized
  end

  def render_unprocessable_entity(opts = {})
    opts = {} unless opts.is_a? Hash
    render json: {
      errors: [{
        title: "Unprocessable entity",
        detail: "The request could not be completed on this resouce"
      }.merge(opts)]
    }, status: :unprocessable_entity
  end

  def render_not_found(opts = {})
    opts = {} unless opts.is_a? Hash
    render json: {
      errors: [{
        title: "Not found",
        detail: "The requested resource was not found"
      }.merge(opts)]
    }, status: :not_found
  end

  def render_bad_request(opts = {})
    opts = {} unless opts.is_a? Hash
    render json: {
      errors: [{
        title: "Bad request",
        detail: "The request could not be completed"
      }.merge(opts)]
    }, status: :bad_request
  end

  def render_conflict(opts = {})
    opts = {} unless opts.is_a? Hash
    render json: {
      errors: [{
        title: "Conflict",
        detail: "The request could not be completed because the resource already exists"
      }.merge(opts)]
    }, status: :conflict
  end

  def render_internal_server_error(opts = {})
    opts = {} unless opts.is_a? Hash
    render json: {
      errors: [{
        title: "Internal server error",
        detail: "Looks like something went wrong!"
      }.merge(opts)]
    }, status: :internal_server_error
  end

  def render_service_unavailable(opts = {})
    opts = {} unless opts.is_a? Hash
    render json: {
      errors: [{
        title: "Service unavailable",
        detail: "We're having a really bad day"
      }.merge(opts)]
    }, status: :service_unavailable
  end

  def render_unprocessable_resource(resource)
    render json: resource, status: :unprocessable_entity, adapter: :json_api,
      serializer: ActiveModel::Serializer::ErrorSerializer
  end
end

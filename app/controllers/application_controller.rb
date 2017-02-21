class ApplicationController < ActionController::API
  include Pundit

  before_action :force_jsonapi_response_format
  after_action :verify_authorized

  rescue_from TypedParameters::UnpermittedParametersError, with: -> (err) { render_bad_request detail: err.message }
  rescue_from TypedParameters::InvalidParameterError, with: -> (err) { render_bad_request detail: err.message, source: err.source }
  rescue_from TypedParameters::InvalidRequestError, with: -> (err) { render_bad_request detail: err.message }
  rescue_from Keygen::Error::InvalidScopeError, with: -> (err) { render_bad_request detail: err.message, source: err.source }
  rescue_from ActionController::UnpermittedParameters, with: -> (err) { render_bad_request detail: err.message }
  rescue_from ActionController::ParameterMissing, with: -> (err) { render_bad_request detail: err.message }
  rescue_from ActiveModel::ForbiddenAttributesError, with: -> { render_bad_request }
  rescue_from ActiveRecord::RecordNotFound, with: -> { render_not_found }
  rescue_from JSON::ParserError, with: -> { render_bad_request }

  rescue_from Pundit::NotAuthorizedError, with: -> (err) { render_forbidden }
  rescue_from Pundit::NotDefinedError, with: -> (err) { render_not_found }

  attr_accessor :current_account
  attr_accessor :current_bearer

  def pundit_user
    current_bearer
  end

  private

  def render_meta(meta)
    render json: { meta: meta.transform_keys! { |k| k.to_s.camelize :lower } }
  end

  def render_forbidden(opts = {})
    skip_authorization

    render json: {
      errors: [{
        title: "Access denied",
        detail: "You do not have permission to complete the request"
      }.merge(opts)]
    }, status: :forbidden
  end

  def render_unauthorized(opts = {})
    skip_authorization

    self.headers["WWW-Authenticate"] = %(Token realm="Application")
    render json: {
      errors: [{
        title: "Unauthorized",
        detail: "You must be authenticated to complete the request"
      }.merge(opts)]
    }, status: :unauthorized
  end

  def render_unprocessable_entity(opts = {})
    skip_authorization

    render json: {
      errors: [{
        title: "Unprocessable entity",
        detail: "The request could not be completed"
      }.merge(opts)]
    }, status: :unprocessable_entity
  end

  def render_not_found(opts = {})
    skip_authorization

    render json: {
      errors: [{
        title: "Not found",
        detail: "The requested resource was not found"
      }.merge(opts)]
    }, status: :not_found
  end

  def render_bad_request(opts = {})
    skip_authorization

    render json: {
      errors: [{
        title: "Bad request",
        detail: "The request could not be completed"
      }.merge(opts)]
    }, status: :bad_request
  end

  def render_conflict(opts = {})
    skip_authorization

    render json: {
      errors: [{
        title: "Conflict",
        detail: "The request could not be completed because of a conflict"
      }.merge(opts)]
    }, status: :conflict
  end

  def render_internal_server_error(opts = {})
    skip_authorization

    render json: {
      errors: [{
        title: "Internal server error",
        detail: "Looks like something went wrong!"
      }.merge(opts)]
    }, status: :internal_server_error
  end

  def render_service_unavailable(opts = {})
    skip_authorization

    render json: {
      errors: [{
        title: "Service unavailable",
        detail: "We're having a really bad day"
      }.merge(opts)]
    }, status: :service_unavailable
  end

  def render_unprocessable_resource(resource)
    skip_authorization

    render jsonapi_error: resource.errors.to_hash.map { |src, errors|
      errors.map do |error|
        Class.new(SerializableError) do
          title "Unprocessable resource"
          detail error
          source do
            pointer(
              if resource.class.reflect_on_association(src)
                "/data/relationships/#{src.to_s.camelize :lower}"
              else
                "/data/attributes/#{src.to_s.camelize :lower}"
              end
            )
          end
        end
      end
    }.flatten.map(&:new), status: :unprocessable_entity
  end

  def force_jsonapi_response_format
    response.headers["Content-Type"] =
      Mime::Type.lookup_by_extension(:jsonapi).to_s
  end
end

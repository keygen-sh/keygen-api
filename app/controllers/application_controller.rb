class ApplicationController < ActionController::API
  include Pundit

  before_action :force_jsonapi_response_format
  before_action :send_rate_limiting_headers
  after_action :verify_authorized

  rescue_from TypedParameters::UnpermittedParametersError, with: -> (err) { render_bad_request detail: err.message }
  rescue_from TypedParameters::InvalidParameterError, with: -> (err) { render_bad_request detail: err.message, source: err.source }
  rescue_from TypedParameters::InvalidRequestError, with: -> (err) { render_bad_request detail: err.message }
  rescue_from Keygen::Error::InvalidScopeError, with: -> (err) { render_bad_request detail: err.message, source: err.source }
  rescue_from Keygen::Error::UnauthorizedError, with: -> { render_unauthorized }
  rescue_from ActionController::UnpermittedParameters, with: -> (err) { render_bad_request detail: err.message }
  rescue_from ActionController::ParameterMissing, with: -> (err) { render_bad_request detail: err.message }
  rescue_from ActiveModel::ForbiddenAttributesError, with: -> { render_bad_request }
  rescue_from ActiveRecord::StatementInvalid, with: -> { render_bad_request } # Invalid UUIDs, non-base64'd creds, etc.
  rescue_from ActiveRecord::RecordNotUnique, with: -> { render_conflict } # Race condition on unique index
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

    self.headers["WWW-Authenticate"] = %(Token realm="Keygen")
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
        detail: "Our services are currently unavailable. Please see https://status.keygen.sh for our uptime status and contact hello@keygen.sh with any questions."
      }.merge(opts)]
    }, status: :service_unavailable
  end

  def render_unprocessable_resource(resource)
    skip_authorization

    errors = resource.errors.to_hash.map { |attr, errs|
      errs.map do |err|
        # Transform users[0].email into [users, 0, email] so that we can put it
        # back together as a proper pointer: users/data/0/attributes/email
        path = attr.to_s.gsub(/\[(\d+)\]/, '.\1').split "."
        src = path.map { |p| p.to_s.camelize :lower }
        pointer = nil

        if resource.class.reflect_on_association(path.first)
          if err != "must exist" && src.size > 1
            src.insert 1, :data # Make sure our pointer is JSONAPI compliant
            src.insert -2, :attributes
          end

          # On account creation, the users association is actually called admins
          # and is used to define the founding admins of the account
          src[0] = "admins" if resource.is_a?(Account) && path.first == "users" && action_name == "create"

          pointer = "/data/relationships/#{src.join '/'}"
        elsif path.first == "base"
          pointer = "/data"
        else
          pointer = "/data/attributes/#{src.join '/'}"
        end

        {
          title: "Unprocessable resource",
          detail: err,
          source: {
            pointer: pointer
          }
        }
      end
    }.flatten

    render json: { errors: errors }, status: :unprocessable_entity
  end

  def force_jsonapi_response_format
    accepted_content_types = HashWithIndifferentAccess.new(
      jsonapi: Mime::Type.lookup_by_extension(:jsonapi).to_s,
      json: Mime::Type.lookup_by_extension(:json).to_s
    )

    content_type = request.headers["Accept"]
    if content_type.nil? || content_type == "*/*"
      response.headers["Content-Type"] = accepted_content_types[:jsonapi]
      return
    end

    if accepted_content_types.values.include?(content_type)
      response.headers["Content-Type"] = content_type
    else
      render_bad_request detail: "Unsupported accept header: #{content_type}"
    end
  end

  def send_rate_limiting_headers
    data = (request.env["rack.attack.throttle_data"] || {})["req/ip"]
    return unless data.present?

    period = data[:period].to_i
    count = data[:count].to_i
    limit = data[:limit].to_i
    now = Time.current

    response.headers["X-RateLimit-Limit"] = limit.to_s
    response.headers["X-RateLimit-Remaining"] = [0, limit - count].max.to_s
    response.headers["X-RateLimit-Reset"] = (now + (period - now.to_i % period)).to_i.to_s
  rescue => e
    Raygun.track_exception e
  end
end

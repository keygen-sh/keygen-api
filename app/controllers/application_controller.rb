# frozen_string_literal: true

class ApplicationController < ActionController::API
  PUBLIC_RATE_LIMIT_KEYS = %w[req/ip/burst/30s req/ip/burst/2m req/ip/burst/5m req/ip/burst/10m]

  include Pundit

  before_action :disable_keep_alive_connections
  before_action :force_jsonapi_response_format
  before_action :send_rate_limiting_headers
  after_action :send_keygen_whoami_headers
  after_action :verify_authorized

  rescue_from TypedParameters::UnpermittedParametersError, with: -> (err) { render_bad_request detail: err.message }
  rescue_from TypedParameters::InvalidParameterError, with: -> (err) { render_bad_request detail: err.message, source: err.source }
  rescue_from TypedParameters::InvalidRequestError, with: -> (err) { render_bad_request detail: err.message }
  rescue_from Keygen::Error::InvalidScopeError, with: -> (err) { render_bad_request detail: err.message, source: err.source }
  rescue_from Keygen::Error::UnauthorizedError, with: -> (err) { render_unauthorized code: err.code }
  rescue_from Keygen::Error::NotFoundError, with: -> (err) {
    if err.model.present? && err.id.present?
      id = Array.wrap(err.id).first

      render_not_found detail: "The requested #{err.model.underscore.humanize.downcase} '#{id}' was not found"
    else
      render_not_found
    end
  }
  rescue_from ActionController::UnpermittedParameters, with: -> (err) { render_bad_request detail: err.message }
  rescue_from ActionController::ParameterMissing, with: -> (err) { render_bad_request detail: err.message }
  rescue_from ActiveModel::RangeError, with: -> { render_bad_request detail: "integer is too large" }
  rescue_from ActiveRecord::StatementInvalid, with: -> (err) {
    # Bad encodings, Invalid UUIDs, non-base64'd creds, etc.
    case err.cause
    when PG::InvalidTextRepresentation
      render_bad_request detail: 'The request could not be completed because it contains badly formatted data (check encoding)', code: 'ENCODING_INVALID'
    when PG::CharacterNotInRepertoire
      render_bad_request detail: 'The request could not be completed because it contains badly encoded data (check encoding)', code: 'ENCODING_INVALID'
    else
      Keygen.logger.exception err

      render_bad_request
    end
  }
  rescue_from PG::Error, with: -> (err) {
    case err.message
    when /incomplete multibyte character/
      render_bad_request detail: 'The request could not be completed because it contains badly encoded data (check encoding)', code: 'ENCODING_INVALID'
    else
      Keygen.logger.exception err

      render_internal_server_error
    end
  }
  rescue_from ActiveRecord::RecordInvalid, with: -> (err) { render_unprocessable_resource err.record }
  rescue_from ActiveRecord::RecordNotUnique, with: -> { render_conflict } # Race condition on unique index
  rescue_from ActiveRecord::RecordNotFound, with: -> (err) {
    if err.model.present? && err.id.present?
      id = Array.wrap(err.id).first

      render_not_found detail: "The requested #{err.model.underscore.humanize.downcase} '#{id}' was not found"
    else
      render_not_found
    end
  }
  rescue_from ArgumentError, with: -> (err) {
    case err.message
    when /invalid byte sequence in UTF-8/,
         /incomplete multibyte character/
      render_bad_request detail: 'The request could not be completed because it contains an invalid byte sequence (check encoding)', code: 'ENCODING_INVALID'
    when /string contains null byte/
      render_bad_request detail: 'The request could not be completed because it contains an unexpected null byte (check encoding)', code: 'ENCODING_INVALID'
    else
      Keygen.logger.exception err

      render_internal_server_error
    end
  }

  rescue_from Pundit::NotAuthorizedError, with: -> (err) { render_forbidden }
  rescue_from Pundit::NotDefinedError, with: -> (err) { render_not_found }

  attr_accessor :current_account
  attr_accessor :current_bearer
  attr_accessor :current_token

  def pundit_user
    current_bearer
  end

  def rate_limiting_info
    throttle_data = (request.env["rack.attack.throttle_data"] || {}).slice(*PUBLIC_RATE_LIMIT_KEYS)
    return unless throttle_data.present?

    key, data = throttle_data.max_by { |k, v| v[:count].to_f / v[:limit].to_f * 100 }
    return unless data.present?

    window = key.split('/').last
    period = data[:period].to_i
    count = data[:count].to_i
    limit = data[:limit].to_i
    now = Time.current

    {
      window: window,
      count: count,
      limit: limit,
      remaining: [0, limit - count].max,
      reset: (now + (period - now.to_i % period)).to_i,
    }
  rescue => e
    Keygen.logger.exception e

    nil
  end

  private

  def render_meta(meta)
    render json: { meta: meta.transform_keys! { |k| k.to_s.camelize :lower } }
  end

  def render_forbidden(opts = {})
    skip_authorization

    render json: {
      meta: { id: request.request_id },
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
      meta: { id: request.request_id },
      errors: [{
        title: "Unauthorized",
        detail: "You must be authenticated to complete the request"
      }.merge(opts)]
    }, status: :unauthorized
  end

  def render_unprocessable_entity(opts = {})
    skip_authorization

    render json: {
      meta: { id: request.request_id },
      errors: [{
        title: "Unprocessable entity",
        detail: "The request could not be completed"
      }.merge(opts)]
    }, status: :unprocessable_entity
  end

  def render_not_found(opts = {})
    skip_authorization

    render json: {
      meta: { id: request.request_id },
      errors: [{
        title: "Not found",
        detail: "The requested resource was not found"
      }.merge(opts)]
    }, status: :not_found
  end

  def render_bad_request(opts = {})
    skip_authorization

    render json: {
      meta: { id: request.request_id },
      errors: [{
        title: "Bad request",
        detail: "The request could not be completed"
      }.merge(opts)]
    }, status: :bad_request
  end

  def render_conflict(opts = {})
    skip_authorization

    render json: {
      meta: { id: request.request_id },
      errors: [{
        title: "Conflict",
        detail: "The request could not be completed because of a conflict"
      }.merge(opts)]
    }, status: :conflict
  end

  def render_payment_required(opts ={})
    skip_authorization

    render json: {
      meta: { id: request.request_id },
      errors: [{
        title: "Payment required",
        detail: "The request could not be completed"
      }.merge(opts)]
    }, status: :payment_required
  end

  def render_internal_server_error(opts = {})
    skip_authorization

    render json: {
      meta: { id: request.request_id },
      errors: [{
        title: "Internal server error",
        detail: "Looks like something went wrong!"
      }.merge(opts)]
    }, status: :internal_server_error
  end

  def render_service_unavailable(opts = {})
    skip_authorization

    render json: {
      meta: { id: request.request_id },
      errors: [{
        title: "Service unavailable",
        detail: "Our services are currently unavailable. Please see https://status.keygen.sh for our uptime status and contact support@keygen.sh with any questions."
      }.merge(opts)]
    }, status: :service_unavailable
  end

  def render_unprocessable_resource(resource)
    skip_authorization

    errors = resource.errors.to_hash.map { |attr, errs|
      details = resource.errors.details[attr]

      errs.each_with_index.map do |err, i|
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

        res = {
          title: "Unprocessable resource",
          detail: err,
          source: {
            pointer: pointer
          }
        }

        # Provide more detailed error codes for resources other than account
        # resources (which are not needed and leaks our validations)
        begin
          detail = details[i][:error] rescue nil

          if detail.present? && !resource.is_a?(Account)
            subject =
              case attr
              when :base
                resource.class.name.underscore
              else
                attr.to_s
              end
            code =
              case detail
              when :greater_than_or_equal_to,
                  :less_than_or_equal_to,
                  :greater_than,
                  :less_than,
                  :equal_to,
                  :other_than
                "invalid"
              when :inclusion,
                   :exclusion
                "not_allowed"
              else
                detail.to_s
              end

            res.merge! code: "#{subject}_#{code}".parameterize.underscore.upcase
          end
        rescue => e
          Keygen.logger.exception e

          raise e
        end

        res
      end
    }.flatten

    # Special cases where a certain limit has been met on the free tier
    status_code =
      if errors&.any? { |e| e[:code] == 'ACCOUNT_LICENSE_LIMIT_EXCEEDED' }
        :payment_required
      else
        :unprocessable_entity
      end

    render json: { meta: { id: request.request_id }, errors: errors }, status: status_code
  end

  def disable_keep_alive_connections
    response.headers["Connection"] = "close"
  end

  def force_jsonapi_response_format
    accepted_content_types = HashWithIndifferentAccess.new(
      jsonapi: Mime::Type.lookup_by_extension(:jsonapi).to_s,
      json: Mime::Type.lookup_by_extension(:json).to_s
    )

    content_type = request.headers["Accept"]&.strip
    accepted = if content_type.present?
                 accepted_content_types.values & content_type.split(/,\s*/)
               else
                 []
               end

    if content_type.nil? || content_type.include?("*/*")
      response.headers["Content-Type"] = accepted_content_types[:jsonapi]
    elsif !accepted.empty?
      response.headers["Content-Type"] = accepted.first.strip
    else
      render_bad_request detail: "Unsupported accept header: #{content_type}"
    end
  end

  def send_rate_limiting_headers
    info = rate_limiting_info
    return if info.nil?

    response.headers["X-RateLimit-Window"]    = info[:window]
    response.headers["X-RateLimit-Count"]     = info[:count]
    response.headers["X-RateLimit-Limit"]     = info[:limit]
    response.headers["X-RateLimit-Remaining"] = info[:remaining]
    response.headers["X-RateLimit-Reset"]     = info[:reset]
  rescue => e
    Keygen.logger.exception e
  end

  def send_keygen_whoami_headers
    response.headers["X-Keygen-Account-Id"] = current_account&.id
    response.headers["X-Keygen-Bearer-Id"] = current_bearer&.id
    response.headers["X-Keygen-Token-Id"] = current_token&.id
  rescue => e
    Keygen.logger.exception e
  end
end

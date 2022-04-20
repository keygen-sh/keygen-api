# frozen_string_literal: true

class ApplicationController < ActionController::API
  include Versionist::Transformer[
    '1.1' => [ReleaseArtifactHasManyToOneTransform],
  ]

  include CurrentRequestAttributes
  include DefaultHeaders
  include RateLimiting
  include Pundit::Authorization

  # NOTE(ezekg) Including these at the end so that they're run last
  include RequestCounter
  include RequestLogger

  # NOTE(ezekg) We're using an around_action here so that our request
  #             logger concern can log the resulting response body.
  #             Otherwise, the logged response may be incorrect.
  around_action :rescue_from_exceptions
  after_action :verify_authorized

  attr_accessor :current_http_scheme
  attr_accessor :current_http_token
  attr_accessor :current_account
  attr_accessor :current_bearer
  attr_accessor :current_token

  def pundit_user
    AuthorizationContext.new(
      account: current_account,
      bearer: current_bearer,
      token: current_token,
    )
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

  def render_unauthorized(**kwargs)
    skip_authorization

    self.headers["WWW-Authenticate"] = %(Bearer realm="keygen")
    render json: {
      meta: { id: request.request_id },
      errors: [{
        title: "Unauthorized",
        detail: "You must be authenticated to complete the request"
      }.merge(kwargs)]
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
        detail: "The requested resource was not found",
        code: "NOT_FOUND",
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
        detail: "Looks like something went wrong! Our engineers have been notified. If you continue to have problems, please contact support@keygen.sh.",
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
        # back together as a proper pointer: /users/data/0/attributes/email
        path    = attr.to_s.gsub(/\[(\d+)\]/, '.\1').split "."
        src     = path.map { |p| p.to_s.camelize :lower }
        pointer = nil
        klass   = resource.class

        if klass.respond_to?(:reflect_on_association) &&
           klass.reflect_on_association(path.first)
          # FIXME(ezekg) Matching on error message is dirty
          case
          when err == "must exist" && src.size > 1
            src.insert 1, :data
            src.insert -2, :relationships
          when err != "must exist" && src.size > 1
            src.insert 1, :data
            src.insert -2, :attributes
          end

          # On account creation, the users association is actually called admins
          # and is used to define the founding admins of the account
          src[0] = "admins" if
            resource.is_a?(Account) &&
            action_name == "create" &&
            path.first == "users"

          pointer = "/data/relationships/#{src.join '/'}"
        elsif path.first == "base"
          pointer = "/data"
        elsif path.first == "id" &&
              path.size == 1
          pointer = "/data/id"
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
                attr.to_s.gsub(/\[\d+\]/, '') # Remove indexes
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
              when :blank
                if pointer.starts_with?("/data/relationships")
                  "not_found"
                else
                  "missing"
                end
              else
                detail.to_s
              end

            res.merge! code: "#{subject}_#{code}".parameterize.underscore.upcase
          end
        rescue => e
          Keygen.logger.exception(e)
        end

        # Provide a docs link when possible
        begin
          if pointer.present?
            (_, docs_type, docs_attr, *) = pointer.delete_prefix('/').split('/')
            docs_object = klass.name.underscore.pluralize

            # FIXME(ezekg) Special case (need to update docs)
            docs_type = 'attrs' if
              docs_type == 'attributes'

            if docs_object.present? && docs_type.present? && docs_attr.present?
              links = {
                about: "https://keygen.sh/docs/api/#{docs_object}/##{docs_object}-object-#{docs_type}-#{docs_attr}"
              }

              res.merge!(links:)
            end
          end
        rescue => e
          Keygen.logger.exception(e)
        end

        # Update sort order for my OCD
        res.slice(
          :title,
          :detail,
          :code,
          :source,
          :links,
        )
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

  def rescue_from_exceptions
    yield
  rescue TypedParameters::UnpermittedParametersError,
         TypedParameters::InvalidRequestError,
         Keygen::Error::BadRequestError,
         ActionController::UnpermittedParameters,
         ActionController::ParameterMissing => e
    render_bad_request detail: e.message
  rescue TypedParameters::InvalidParameterError,
         Keygen::Error::InvalidScopeError => e
    render_bad_request detail: e.message, source: e.source
  rescue Keygen::Error::UnauthorizedError => e
    kwargs = { code: e.code }

    kwargs[:detail] = e.detail if
      e.detail.present?

    # Add additional properties based on code
    case e.code
    when 'LICENSE_NOT_ALLOWED',
        'LICENSE_INVALID'
      kwargs[:links] = { about: 'https://keygen.sh/docs/api/authentication/#license-authentication' }
    when 'TOKEN_NOT_ALLOWED',
         'TOKEN_INVALID'
      kwargs[:links] = { about: 'https://keygen.sh/docs/api/authentication/#token-authentication' }
    when 'TOKEN_MISSING'
      kwargs[:links] = { about: 'https://keygen.sh/docs/api/authentication/' }
    end

    render_unauthorized(**kwargs)
  rescue Keygen::Error::ForbiddenError => e
    if e.detail.present?
      render_forbidden code: e.code, detail: e.detail
    else
      render_forbidden code: e.code
    end
  rescue Keygen::Error::NotFoundError,
         ActiveRecord::RecordNotFound => e
    if e.model.present? && e.id.present?
      resource = e.model.underscore.humanize.downcase
      id       = Array.wrap(e.id).first

      render_not_found detail: "The requested #{resource} '#{id}' was not found"
    else
      render_not_found
    end
  rescue Keygen::Error::InvalidAccountDomainError,
         Keygen::Error::InvalidAccountIdError
    render_not_found
  rescue ActiveModel::RangeError
    render_bad_request detail: "integer is too large"
  rescue ActiveRecord::StatementInvalid => e
    # Bad encodings, Invalid UUIDs, non-base64'd creds, etc.
    case e.cause
    when PG::InvalidTextRepresentation
      render_bad_request detail: 'The request could not be completed because it contains badly formatted data (check encoding)', code: 'ENCODING_INVALID'
    when PG::CharacterNotInRepertoire
      render_bad_request detail: 'The request could not be completed because it contains badly encoded data (check encoding)', code: 'ENCODING_INVALID'
    when PG::UniqueViolation
      render_conflict
    else
      Keygen.logger.exception(e)

      render_bad_request
    end
  rescue PG::Error => e
    case e.message
    when /incomplete multibyte character/
      render_bad_request detail: 'The request could not be completed because it contains badly encoded data (check encoding)', code: 'ENCODING_INVALID'
    else
      Keygen.logger.exception(e)

      render_internal_server_error
    end
  rescue ActiveRecord::RecordNotSaved,
         ActiveRecord::RecordInvalid => e
    render_unprocessable_resource e.record
  rescue ActiveRecord::RecordNotUnique
    render_conflict # Race condition on unique index
  rescue ActiveModel::ValidationError => e
    render_unprocessable_resource e.model
  rescue ArgumentError => e
    case e.message
    when /invalid byte sequence in UTF-8/,
          /incomplete multibyte character/
      render_bad_request detail: 'The request could not be completed because it contains an invalid byte sequence (check encoding)', code: 'ENCODING_INVALID'
    when /string contains null byte/
      render_bad_request detail: 'The request could not be completed because it contains an unexpected null byte (check encoding)', code: 'ENCODING_INVALID'
    else
      Keygen.logger.exception(e)

      render_internal_server_error
    end
  rescue Pundit::NotDefinedError => e
    render_not_found
  rescue Pundit::NotAuthorizedError
    msg = if current_bearer.present?
            'You do not have permission to complete the request (ensure the token bearer is allowed to access this resource)'
          else
            'You do not have permission to complete the request (ensure a token is present and valid)'
          end

    render_forbidden detail: msg
  end

  class AuthorizationContext < OpenStruct; end
end

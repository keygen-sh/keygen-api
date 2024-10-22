# frozen_string_literal: true

class ApplicationController < ActionController::API
  include Rendering::JSON
  include CurrentRequestAttributes
  include DefaultUrlOptions
  include RateLimiting
  include TypedParams::Controller
  include ActionPolicy::Controller

  # NOTE(ezekg) The remaining concerns use around_action, so the order
  #             here is very explicit.

  # 1. Requests are counted at the very end of the around_action chain,
  #    so the concern is added first.
  include RequestCounter

  # 2. Requests are logged after all migrations and errors. Again, this
  #    is run near the end of the around_action chain.
  include RequestLogger

  # 3. Responses are signed after migrations and errors.
  include SignatureHeaders

  # 4. Migrations are run after errors have been caught.
  include RequestMigrations::Controller::Migrations

  # NOTE(ezekg) We're using an around_action here so that our request
  #             logger concern can log the resulting response body.
  #             Otherwise, the logged response may be incorrect.
  #
  # 5. Errors are caught and handled before migrations.
  around_action :rescue_from_exceptions

  # 6. Headers are added before migrations, so they can be migrated
  #    if needed, with the exception of the signature headers.
  include DefaultHeaders

  attr_accessor :current_http_scheme
  attr_accessor :current_http_token
  attr_accessor :current_account
  attr_accessor :current_environment
  attr_accessor :current_bearer
  attr_accessor :current_token

  # Action policy authz contexts
  authorize :account,     through: :current_account
  authorize :environment, through: :current_environment
  authorize :bearer,      through: :current_bearer
  authorize :token,       through: :current_token

  verify_authorized

  def jsonapi_expose
    {
      url_helpers: Rails.application.routes.url_helpers,
      account: current_account,
      bearer: current_bearer,
      token: current_token,
    }
  end

  def current_api_version
    RequestMigrations.config.request_version_resolver.call(request)
  end

  private

  # NOTE(ezekg) Remove memoization of authorization context. This allows us
  #             to use authorized_scope() before authorize!() in controllers
  #             for nested resources, e.g. /v1/releases/:id/artifacts.
  #
  # See: https://github.com/palkan/action_policy/issues/217
  def authorization_context = build_authorization_context

  def render_meta(meta)
    render json: { meta: meta.deep_transform_keys { _1.to_s.camelize :lower } }
  end

  def render_no_content(**kwargs)
    render status: :no_content
  end

  def render_forbidden(**kwargs)
    skip_verify_authorized!

    respond_to do |format|
      format.any {
        render status: :forbidden, json: {
          meta: { id: request.request_id },
          errors: [{
            title: 'Access denied',
            detail: 'You do not have permission to complete the request',
            **kwargs,
          }],
        }
      }
      format.html {
        render html: 'Forbidden', status: :forbidden
      }
      format.text {
        head :forbidden
      }
    end
  end

  def render_unauthorized(**kwargs)
    skip_verify_authorized!

    self.headers['WWW-Authenticate'] = %(Bearer realm="keygen")

    respond_to do |format|
      format.any {
        render status: :unauthorized, json: {
          meta: { id: request.request_id },
          errors: [{
            title: 'Unauthorized',
            detail: 'You must be authenticated to complete the request',
            **kwargs,
          }],
        }
      }
      format.html {
        render html: 'Unauthorized', status: :unauthorized
      }
      format.text {
        head :unauthorized
      }
    end
  end

  def render_unprocessable_entity(**kwargs)
    skip_verify_authorized!

    respond_to do |format|
      format.any {
        render status: :unprocessable_entity, json: {
          meta: { id: request.request_id },
          errors: [{
            title: 'Unprocessable entity',
            detail: 'The request could not be completed',
            **kwargs,
          }],
        }
      }
      format.html {
        render html: 'Unprocessable Entity', status: :unprocessable_entity
      }
      format.text {
        head :unprocessable_entity
      }
    end
  end

  def render_not_found(**kwargs)
    skip_verify_authorized!

    respond_to do |format|
      format.any {
        render status: :not_found, json: {
          meta: { id: request.request_id },
          errors: [{
            title: 'Not found',
            detail: 'The requested endpoint was not found (check your HTTP method, Accept header, and URL path)',
            code: 'NOT_FOUND',
            **kwargs,
          }],
        }
      }
      format.html {
        render html: 'Not Found', status: :not_found
      }
      format.text {
        head :not_found
      }
    end
  end

  def render_bad_request(**kwargs)
    skip_verify_authorized!

    respond_to do |format|
      format.any {
        render status: :bad_request, json: {
          meta: { id: request.request_id },
          errors: [{
            title: 'Bad request',
            detail: 'The request could not be completed',
            **kwargs,
          }],
        }
      }
      format.html {
        render html: 'Bad Request', status: :bad_request
      }
      format.text {
        head :bad_request
      }
    end
  end

  def render_conflict(**kwargs)
    skip_verify_authorized!

    respond_to do |format|
      format.any {
        render status: :conflict, json: {
          meta: { id: request.request_id },
          errors: [{
            title: 'Conflict',
            detail: 'The request could not be completed because of a conflict',
            **kwargs,
          }],
        }
      }
      format.html {
        render html: 'Conflict', status: :conflict
      }
      format.text {
        head :conflict
      }
    end
  end

  def render_payment_required(**kwargs)
    skip_verify_authorized!

    respond_to do |format|
      format.any {
        render status: :payment_required, json: {
          meta: { id: request.request_id },
          errors: [{
            title: 'Payment required',
            detail: 'The request could not be completed',
            **kwargs,
          }],
        }
      }
      format.html {
        render html: 'Payment Required', status: :payment_required
      }
      format.text {
        head :payment_required
      }
    end
  end

  def render_internal_server_error(**kwargs)
    skip_verify_authorized!

    respond_to do |format|
      format.any {
        render status: :internal_server_error, json: {
          meta: { id: request.request_id },
          errors: [{
            title: 'Internal server error',
            detail: 'Looks like something went wrong! Our engineers have been notified. If you continue to have problems, please contact support@keygen.sh.',
            **kwargs,
          }],
        }
      }
      format.html {
        render html: 'Internal Server Error', status: :internal_server_error
      }
      format.text {
        head :internal_server_error
      }
    end
  end

  def render_service_unavailable(**kwargs)
    skip_verify_authorized!

    respond_to do |format|
      format.any {
        render status: :service_unavailable, json: {
          meta: { id: request.request_id },
          errors: [{
            title: 'Service unavailable',
            detail: 'Our services are currently unavailable. Please see https://status.keygen.sh for our uptime status and contact support@keygen.sh with any questions.',
            **kwargs,
          }],
        }
      }
      format.html {
        render html: 'Service Unavailable', status: :service_unavailable
      }
      format.text {
        head :service_unavailable
      }
    end
  end

  def render_unprocessable_resource(resource)
    errors = resource.errors.as_jsonapi
    meta   = { id: request.request_id }

    # NOTE(ezekg) We're using #reverse_each here so that we can delete errors
    #             in-place, e.g. in the case of a non-public error, without
    #             botching the iterator's indexes.
    errors.reverse_each do |error|
      # Fixup various error codes and pointers to match our objects, e.g.
      # some relationships are invisible, exposed as attributes.
      case error
      in source: { pointer: %r{^/data/relationships/users/(.*+)} } if resource in Account
        error.pointer = "/data/relationships/admins/#{$1}"
      in source: { pointer: %r{^/data/attributes/permission_?ids$}i },
         code: /^PERMISSION_IDS_(.+)/
        error.pointer = '/data/attributes/permissions'
        error.code    = "PERMISSIONS_#{$1}"
      in source: { pointer: %r{^/data/relationships/role/data/attributes/permission_?ids}i },
         code: /^ROLE_PERMISSION_IDS_(.+)/
        error.pointer = '/data/attributes/permissions'
        error.code    = "PERMISSIONS_#{$1}"
      in source: { pointer: %r{^/data/relationships/role} }
        error.pointer = '/data/attributes/role'
      in source: { pointer: %r{^/data/relationships/filetype} }
        error.pointer = '/data/attributes/filetype'
      in source: { pointer: %r{^/data/relationships/channel} }
        error.pointer = '/data/attributes/channel'
      in source: { pointer: %r{^/data/relationships/platform} }
        error.pointer = '/data/attributes/platform'
      in source: { pointer: %r{^/data/relationships/engine} }
        error.pointer = '/data/attributes/engine'
      in source: { pointer: %r{^/data/relationships/arch} }
        error.pointer = '/data/attributes/arch'
      in source: { pointer: %r{^/data/attributes/admins} }
        error.pointer = '/data/relationships/admins'
      in code: /^(?:LICENSE_)?USERS?_LIMIT_EXCEEDED$/ # normalize user limit errors
        error.pointer = '/data/relationships/users'
        error.code    = 'USER_LIMIT_EXCEEDED'
      in code: /ACCOUNT_NOT_ALLOWED$/ # private error
        errors.delete(error)
      else
      end

      # Add a helpful link to the docs when possible.
      # FIXME(ezekg) Adjust topic to match our docs.
      topic = case resource
              in LicenseEntitlement | PolicyEntitlement
                'entitlements'
              in LicenseUser
                'licenses'
              in MachineComponent
                'components'
              in MachineProcess
                'processes'
              in ReleaseArtifact
                'artifacts'
              in ReleaseEngine
                'engines'
              in ReleaseChannel
                'channels'
              in ReleasePlatform
                'platforms'
              in ReleaseArch
                'arches'
              else
                resource.class.name.underscore
                                   .dasherize
                                   .pluralize
              end

      hash = "#{topic}-object".then { |s|
        case error
        in source: { pointer: %r{/relationships/([^/]+)} }
          s << '-relationships-' << $1
        in source: { pointer: %r{/attributes/([^/]+)} }
          s << '-attrs-' << $1
        else
          s
        end
      }

      error.links = {
        about: "https://keygen.sh/docs/api/#{topic}/##{hash}",
      }
    end

    # Special cases where a certain limit has been met on the free tier
    status = if errors.any? { _1.code == 'ACCOUNT_ALU_LIMIT_EXCEEDED' }
               :payment_required
             else
               :unprocessable_entity
             end

    render status:, json: {
      errors:,
      meta:,
    }
  end

  def rescue_from_exceptions
    yield
  rescue TypedParams::UnpermittedParameterError,
         TypedParams::InvalidParameterError => e
    source = e.source == :query ? :parameter : :pointer
    path   = e.source == :query ? e.path.to_s : e.path.to_json_pointer

    render_bad_request detail: e.message, source: { source => path }
  rescue Keygen::Error::BadRequestError,
         ActionController::UnpermittedParameters,
         ActionController::ParameterMissing => e
    render_bad_request detail: e.message
  rescue Keygen::Error::UnsupportedParameterError,
         Keygen::Error::InvalidParameterError,
         Keygen::Error::UnsupportedHeaderError,
         Keygen::Error::InvalidHeaderError => e
    kwargs = { detail: e.message, source: e.source }

    kwargs[:code] = e.code if
      e.code.present?

    render_bad_request(**kwargs)
  rescue Keygen::Error::UnauthorizedError => e
    kwargs = { code: e.code }

    kwargs[:detail] = e.detail if
      e.detail.present?

    kwargs[:source] = e.source if
      e.source.present?

    # Add additional properties based on code
    case e.code
    when 'LICENSE_INVALID'
      kwargs[:links] = { about: 'https://keygen.sh/docs/api/authentication/#license-authentication' }
    when 'TOKEN_INVALID'
      kwargs[:links] = { about: 'https://keygen.sh/docs/api/authentication/#token-authentication' }
    when 'TOKEN_MISSING'
      kwargs[:links] = { about: 'https://keygen.sh/docs/api/authentication/' }
    end

    render_unauthorized(**kwargs)
  rescue Keygen::Error::ForbiddenError => e
    kwargs = { code: e.code }

    kwargs[:detail] = e.detail if
      e.detail.present?

    kwargs[:source] = e.source if
      e.source.present?

    # Add additional properties based on code
    case e.code
    when 'LICENSE_NOT_ALLOWED'
      kwargs[:links] = { about: 'https://keygen.sh/docs/api/authentication/#license-authentication' }
    when 'TOKEN_NOT_ALLOWED'
      kwargs[:links] = { about: 'https://keygen.sh/docs/api/authentication/#token-authentication' }
    end

    render_forbidden(**kwargs)
  rescue Keygen::Error::NotFoundError,
         ActiveRecord::RecordNotFound => e
    if e.model.present?
      resource = e.model.underscore.humanize(capitalize: false)

      if e.id.present?
        id = Array.wrap(e.id).first

        render_not_found detail: "The requested #{resource} '#{id}' was not found"
      else
        render_not_found detail: "The requested #{resource} was not found"
      end
    else
      render_not_found detail: 'The requested resource was not found'
    end
  rescue Keygen::Error::InvalidAccountDomainError,
         Keygen::Error::InvalidAccountIdError => e
    render_not_found detail: e.message
  rescue Keygen::Error::InvalidEnvironmentError => e
    render_bad_request detail: e.message, code: 'ENVIRONMENT_INVALID', source: { header: 'Keygen-Environment' }
  rescue ActiveModel::RangeError
    render_bad_request detail: "integer is too large"
  rescue ActiveRecord::StatementInvalid => e
    # Bad encodings, Invalid UUIDs, non-base64'd creds, etc.
    case e.cause
    when PG::InvalidTextRepresentation
      render_bad_request detail: 'The request could not be completed because it contains an invalid byte sequence (check encoding)', code: 'ENCODING_INVALID'
    when PG::CharacterNotInRepertoire
      render_bad_request detail: 'The request could not be completed because it contains an invalid byte sequence (check encoding)', code: 'ENCODING_INVALID'
    when PG::UniqueViolation
      render_conflict
    else
      Keygen.logger.exception(e)

      render_bad_request
    end
  rescue PG::Error => e
    case e.message
    when /incomplete multibyte character/
      render_bad_request detail: 'The request could not be completed because it contains an invalid byte sequence (check encoding))', code: 'ENCODING_INVALID'
    else
      Keygen.logger.exception(e)

      render_internal_server_error
    end
  rescue ActiveRecord::RecordNotSaved,
         ActiveRecord::RecordInvalid => e
    render_unprocessable_resource e.record
  rescue ActiveRecord::RecordNotUnique
    render_conflict # Race condition on unique index
  rescue ActiveRecord::NestedAttributes::TooManyRecords
    render_unprocessable_entity detail: 'too many records'
  rescue ActiveModel::ValidationError => e
    render_unprocessable_resource e.model
  rescue Encoding::CompatibilityError,
         ArgumentError => e
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
  rescue ActionPolicy::NotFound => e
    Keygen.logger.warn { "[action_policy] message=#{e.message}" }
    Keygen.logger.exception(e)

    render_internal_server_error
  rescue ActionPolicy::Unauthorized => e
    Keygen.logger.warn { "[action_policy] policy=#{e.policy} rule=#{e.rule} message=#{e.message} reasons=#{e.result.reasons&.reasons}" }

    # FIXME(ezekg) Does Action Policy provide a better API for fetching the reason?
    reasons = [].tap do |accum|
      e.result.reasons.details.each do |policy, rules|
        case rules
        in [Symbol, *] => symbols
          # We should always use inline_reasons: when calling allowed_to?().
          # Consider symbol reasons a bug, as they are noncommunicative.
          symbols.each do |symbol|
            Keygen.logger.warn { "[action_policy] policy=#{policy} symbol=#{symbol}" }
          end
        in [String, *]
          rules.each { accum << _1 }
        in [Hash, *]
          rules.each do |rule|
            rule.values.each { accum << _1 }
          end
        end
      end
    rescue => e
      Keygen.logger.exception(e)
    end

    detail = case
             when reasons.any?
               "You do not have permission to complete the request (#{reasons.first})"
             when current_bearer.present?
               'You do not have permission to complete the request (ensure the token or license is allowed to access all resources)'
             else
               'You do not have permission to complete the request (ensure a token or license is present and valid)'
             end

    render_forbidden(detail:)
  rescue RequestMigrations::UnsupportedVersionError
    render_bad_request(
      detail: 'unsupported API version requested',
      code: 'INVALID_API_VERSION',
      links: {
        about: 'https://keygen.sh/docs/api/versioning/',
      },
    )
  end

  def prefers?(preference)
    preferences = request.headers.fetch('Prefer') { request.query_parameters.fetch(:prefer, '').to_s }
                                 .split(',')
                                 .map(&:strip)

    return false if
      preferences.empty?

    preferences.include?(preference.to_s)
  end

  def require_ee!(entitlements: [])
    return if
      Keygen.ee? && Keygen.ee { _1.entitled?(*entitlements) }

    if entitlements.any?
      render_forbidden(detail: "must have an EE license with the following entitlements to access this resource: #{entitlements.join(', ')}")
    else
      render_forbidden(detail: "must have an EE license to access this resource")
    end
  end
end

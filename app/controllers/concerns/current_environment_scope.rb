# frozen_string_literal: true

module CurrentEnvironmentScope
  extend ActiveSupport::Concern

  ENVIRONMENT_HEADER_KEY = 'Keygen-Environment'.freeze
  ENVIRONMENT_PARAM_KEY  = 'environment'.freeze

  included do
    include ActiveSupport::Callbacks

    # Define callback system for current environment to allow controllers to run certain
    # callbacks before and after the current environment has been set.
    define_callbacks :current_environment_scope

    # Set the current environment after the current account has been set.
    after_current_account :set_current_environment

    def set_current_environment
      return if
        current_account.nil?

      run_callbacks :current_environment_scope do
        environment_id =
          case
          when request.headers.key?(ENVIRONMENT_HEADER_KEY)
            raise Keygen::Error::UnsupportedHeaderError.new('is unsupported', header: ENVIRONMENT_HEADER_KEY, code: :ENVIRONMENT_NOT_SUPPORTED) unless
              Keygen.ee? && Keygen.ee { _1.entitled?(:environments) }

            request.headers[ENVIRONMENT_HEADER_KEY]
          when request.params.key?(ENVIRONMENT_PARAM_KEY)
            raise Keygen::Error::UnsupportedParameterError.new('is unsupported', parameter: ENVIRONMENT_PARAM_KEY, code: :ENVIRONMENT_NOT_SUPPORTED) unless
              Keygen.ee? && Keygen.ee { _1.entitled?(:environments) }

            request.params[ENVIRONMENT_PARAM_KEY]
          else
            next
          end

        environment = (
          Current.environment ||= ResolveEnvironmentService.call(
            environment: environment_id,
            account: current_account,
          )
        )

        @current_environment = environment
      end
    end
  end

  class_methods do
    def before_current_environment(callback)
      set_callback :current_environment_scope, :before, callback
    end

    def after_current_environment(callback)
      set_callback :current_environment_scope, :after, callback
    end
  end
end

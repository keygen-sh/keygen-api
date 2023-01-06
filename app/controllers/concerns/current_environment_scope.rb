# frozen_string_literal: true

module CurrentEnvironmentScope
  extend ActiveSupport::Concern

  ENVIRONMENT_HEADER_KEY = 'Keygen-Environment'.freeze

  included do
    include ActiveSupport::Callbacks

    mattr_accessor :environmental_controllers,
      default: Set.new

    # Define callback system for current environment to allow controllers to run certain
    # callbacks before and after the current environment has been set.
    define_callbacks :current_environment_scope

    around_action :assert_supports_environment!

    def supports_environment? = environmental_controllers.include?(self.class)
    def provided_environment? = request.headers.key?(ENVIRONMENT_HEADER_KEY)

    def set_current_environment
      run_callbacks :current_environment_scope do
        next unless
          provided_environment?

        Current.environment ||= ResolveEnvironmentService.call(
          environment: request.headers[ENVIRONMENT_HEADER_KEY],
          account: Current.account,
        )

        @current_environment = Current.environment
      end
    end

    def assert_supports_environment!
      raise Keygen::Error::UnsupportedHeaderError.new('environment is not supported for this resource', header: ENVIRONMENT_HEADER_KEY) if
        provided_environment? && !supports_environment?

      yield
    end
  end

  class_methods do
    def supports_environment
      before_action :set_current_environment

      environmental_controllers << self
    end

    def before_current_environment(callback)
      set_callback :current_environment_scope, :before, callback
    end

    def after_current_environment(callback)
      set_callback :current_environment_scope, :after, callback
    end
  end
end

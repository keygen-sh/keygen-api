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

    before_action :assert_environment_support!

    def environment_supported? = environmental_controllers.include?(self.class)
    def environment_provided?  = request.headers.key?(ENVIRONMENT_HEADER_KEY)

    def set_current_environment
      return if
        current_account.nil?

      run_callbacks :current_environment_scope do
        next unless
          environment_provided?

        environment = (
          Current.environment ||= ResolveEnvironmentService.call(
            environment: request.headers[ENVIRONMENT_HEADER_KEY],
            account: current_account,
          )
        )

        @current_environment = environment
      end
    end

    def assert_environment_support!
      return unless
        environment_provided?

      unless environment_supported?
        raise Keygen::Error::UnsupportedHeaderError.new('environment is not supported for this resource', header: ENVIRONMENT_HEADER_KEY)
      end
    end
  end

  class_methods do
    def supports_environment
      after_current_account :set_current_environment

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

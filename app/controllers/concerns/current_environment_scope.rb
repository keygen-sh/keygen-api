# frozen_string_literal: true

module CurrentEnvironmentScope
  extend ActiveSupport::Concern

  included do
    include ActiveSupport::Callbacks

    # Define callback system for current environment to allow controllers to run certain
    # callbacks before and after the current environment has been set.
    define_callbacks :current_environment_scope

    def scope_to_current_environment!
      run_callbacks :current_environment_scope do
        Current.environment ||= if Keygen.ee?
                                  ResolveEnvironmentService.call(
                                    account: Current.account,
                                    request:,
                                  )
                                else
                                  nil
                                end

        @current_environment = Current.environment
      end
    end

    def self.before_current_environment(callback)
      set_callback :current_environment_scope, :before, callback
    end

    def self.after_current_environment(callback)
      set_callback :current_environment_scope, :after, callback
    end
  end
end

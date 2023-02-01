# frozen_string_literal: true

module Environmental
  extend ActiveSupport::Concern

  included do
    ##
    # for_environment scopes the current resource to an environment.
    #
    # When :strict is false, some environments MAY bleed into others. For example,
    # a shared environment may include resources from the global environment, and
    # the global environment will include resources from all environments. To
    # scope to a specific environment without others bleeding into the
    # results, enable :strict mode.
    scope :for_environment, -> environment, strict: false {
      case
      when environment.nil?
        strict ? where(environment: nil) : self
      when environment.isolated?
        where(environment:)
      when environment.shared?
        strict ? where(environment:) : where(environment: [nil, environment])
      else
        none
      end
    }
  end

  class_methods do
    ##
    # has_environment configures the model to be scoped to an optional environment.
    #
    # Use :default to automatically configure a default environment for the model.
    # Accepts a proc that resolves into an environment or environment ID. Also
    # adds validations that assert the model's environment is compatible with
    # the resolved default environment.
    def has_environment(default: nil)
      belongs_to :environment,
        optional: true

      after_initialize -> { self.environment ||= Current.environment },
        if: -> {
          has_attribute?(:environment) && new_record?
        }

      # Validate the association only if we've been given an environment (because it's optional)
      validates :environment,
        presence: { message: 'must exist' },
        scope: { by: :account_id },
        unless: -> {
          environment_id_before_type_cast.nil?
        }

      # TODO(ezekg) Extract this into a concern or an attr_immutable lib?
      validate on: %i[update] do
        next unless
          environment_id_changed? && environment_id != environment_id_was

        errors.add(:environment, :not_allowed, message: 'is immutable')
      end

      # Define generic logic for environment inheritance
      unless default.nil?
        # NOTE(ezekg) This after initialize hook is in addition to the default one above.
        #             Using environment_id here to prevent superfluous queries.
        module_eval <<~RUBY, __FILE__, __LINE__ + 1
          after_initialize -> {
              case default.call(self)
              in Environment => env
                self.environment ||= env
              in String => id
                self.environment_id ||= id
              in nil
                # already nil
              end
            },
            if: -> {
              has_attribute?(:environment_id) && new_record?
            }
        RUBY

        # We also want to assert that the model's current environment is compatible
        # with its default environment (if a default is set).
        module_eval <<~RUBY, __FILE__, __LINE__ + 1
          validate on: %i[create] do
            default_environment_id = case default.call(self)
                                     in Environment => env
                                       env.id
                                     in String => id
                                       id
                                     in nil
                                       nil
                                     end

            errors.add :environment, :not_allowed, message: "must be compatible with default environment" unless
              case
              when environment.nil?
                default_environment_id.nil?
              when environment.isolated?
                default_environment_id == environment_id
              when environment.shared?
                default_environment_id == environment_id || default_environment_id.nil?
              end
          end
        RUBY
      end
    end
  end
end

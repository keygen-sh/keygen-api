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
    # Use :inherits_from to automatically configure the default environment of
    # the model. Accepts an association name. Also adds validations that assert
    # the model's environment is compatible with the association's.
    def has_environment(inherits_from: nil)
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
      unless inherits_from.nil?
        # NOTE(ezekg) This after initialize hook is in addition to the default one above.
        #             Using environment_id here to prevent superfluous queries.
        module_eval <<~RUBY, __FILE__, __LINE__ + 1
          after_initialize -> { self.environment_id ||= #{inherits_from}&.environment_id },
            if: -> {
              has_attribute?(:environment_id) && new_record?
            }
        RUBY

        # We also want to assert that the model's environment matches the environment
        # of the association it inherits an environment from (if any).
        module_eval <<~RUBY, __FILE__, __LINE__ + 1
          validate on: %i[create] do
            errors.add :environment, :not_allowed, message: "must be compatible with #{inherits_from}'s environment" unless
              case
              when environment.nil?
                #{inherits_from}.environment.nil?
              when environment.isolated?
                #{inherits_from}.environment_id == environment_id
              when environment.shared?
                #{inherits_from}.environment_id == environment_id || #{inherits_from}.environment_id.nil?
              end
          end
        RUBY
      end
    end
  end
end

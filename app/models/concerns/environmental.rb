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
    # Accepts a proc that resolves into an environment or environment ID.
    #
    # Use :constraint to add validations to the model's environment, e.g. to assert
    # a model's environment is compatible with an association's environment.
    def has_environment(default: nil, constraint: nil)
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

      unless default.nil?
        # NOTE(ezekg) This after initialize hook is in addition to the default one above.
        module_eval <<~RUBY, __FILE__, __LINE__ + 1
          after_initialize -> {
              self.environment_id ||= case default.call(self)
                                      in Environment => env
                                        env.id
                                      in String => id
                                        id
                                      in nil
                                        nil
                                      end
            },
            if: -> {
              has_attribute?(:environment_id) && new_record?
            }
        RUBY
      end

      unless constraint.nil?
        # We also want to assert that the model's current environment is compatible
        # with its environment constraint (if a constraint is set).
        module_eval <<~RUBY, __FILE__, __LINE__ + 1
          validate on: %i[create] do
            errors.add :environment, :not_allowed, message: 'must be compatible with environment constraint' unless
              constraint.call(self)
          end
        RUBY
      end
    end
  end
end

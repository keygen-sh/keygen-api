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
        after_initialize -> {
            value = case default.arity
                    when 1
                      instance_exec(self, &default)
                    when 0
                      instance_exec(&default)
                    else
                      raise ArgumentError, 'expected proc with 0..1 arguments'
                    end

            self.environment_id ||= case value
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
      end

      unless constraint.nil?
        # We also want to assert that the model's current environment is compatible
        # with its environment constraint (if a constraint is set).
        #
        # NOTE(ezekg) We're using a lambda here so that we can return early out
        #             of the nested catch blocks (next won't work).
        validator = -> {
          catch :fail do
            catch :pass do
              case constraint.arity
              when 1
                instance_exec(self, &constraint)
              when 0
                instance_exec(&constraint)
              else
                raise ArgumentError, 'expected proc with 0..1 arguments'
              end
            end

            # Unless our constraint throws :fail, we're all good.
            return
          end

          # If we reach this, our constraint threw :fail.
          errors.add :environment, :not_allowed, message: 'is invalid (constraint failed)'
        }

        validate on: %i[create], &validator
      end
    end
  end
end

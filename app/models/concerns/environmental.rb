# frozen_string_literal: true

module Environmental
  extend ActiveSupport::Concern

  included do
    include Keygen::EE::ProtectedMethods[:environment_id=, :environment=, entitlements: %i[environments]]
    include Dirtyable

    ##
    # with_environment returns all resources that have an environment.
    scope :with_environment, -> {
      where.associated(:environment)
    }

    ##
    # without_environment returns all resources without an environment.
    scope :without_environment, -> {
      where.missing(:environment)
    }

    ##
    # for_environment scopes the current resource to an environment.
    #
    # When :strict is false, some environments MAY bleed into others. For example,
    # a shared environment may include resources from the global environment, and
    # the global environment will include resources from all environments. To
    # scope to a specific environment without others bleeding into the
    # results, enable :strict mode.
    scope :for_environment, -> environment, strict: false {
      environment = case environment
                    in String => code unless code in UUID_RE
                      return none # We do not currently support filtering via environment codes.
                    in UUID_RE => id
                      return none unless
                        env = Environment.find_by(id:)

                      env
                    in Environment => env
                      env
                    in nil
                      nil
                    end

      case
      when environment.nil?
        strict ? where(environment: nil) : self
      when environment.isolated?
        where(environment:)
      when environment.shared?
        strict ? where(environment:) : where(environment: [nil, *environment])
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
    # Accepts a proc that resolves into an Environment or environment ID.
    def has_environment(default: nil, **kwargs)
      belongs_to :environment, optional: true, **kwargs

      tracks_attributes :environment_id,
                        :environment

      # Hook into both initialization and validation to ensure the current environment
      # is applied to new records (given no :environment was provided).
      #
      # We're not using belongs_to(default:) because it only adds a before_validation
      # callback, but we want to also do it after_initialize because new children
      # may rely on the environment being set on their parent.
      after_initialize -> { self.environment_id ||= Current.environment&.id },
        unless: -> { environment_id_attribute_assigned? || environment_attribute_assigned? },
        if: -> { new_record? && environment.nil? }

      before_validation -> { self.environment_id ||= Current.environment&.id },
        unless: -> { environment_id_attribute_assigned? || environment_attribute_assigned? },
        if: -> { new_record? && environment.nil? },
        on: %i[create]

      # Validate the association only if we've been given an environment (because it's optional).
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
        # NOTE(ezekg) These default hooks are in addition to the default hooks above.
        fn = -> {
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
        }

        # Again, we want to make absolutely sure our default is applied.
        after_initialize unless: -> { environment_id_attribute_assigned? || environment_attribute_assigned? },
          if: -> { new_record? && environment.nil? },
          &fn

        before_validation unless: -> { environment_id_attribute_assigned? || environment_attribute_assigned? },
          if: -> { new_record? && environment.nil? },
          on: %i[create],
          &fn
      end

      # We also want to assert that the model's current environment is compatible
      # with all of its :belongs_to associations that are environmental.
      unless (reflections = reflect_on_all_associations(:belongs_to)).empty?
        reflections.reject { _1.name == :environment }
                   .each do |reflection|
          # Assert that we're either dealing with a polymorphic association (and in that case
          # we'll perform the environment assert later during validation), or we want to
          # assert the :belongs_to has an :environment association to assert against.
          next unless
            (reflection.options in polymorphic: true) || reflection.klass < Environmental

          # Perform asserts on create and update.
          validate on: %i[create update] do
            next unless
              environment_id_changed? || public_send("#{reflection.foreign_key}_changed?")

            association = public_send(reflection.name)
            next if
              association.nil?

            # Again, assert that the association has an :environment association to assert
            # against (this is mainly here for polymorphic associations).
            next unless
              association.class < Environmental

            # Add a validation error if the current model's environment is incompatible with
            # its association's environment.
            errors.add :environment, :not_allowed, message: "must be compatible with #{reflection.name} environment" unless
              case
              when environment.nil?
                association.environment_id.nil?
              when environment.isolated?
                association.environment_id == environment_id
              when environment.shared?
                association.environment_id == environment_id || association.environment_id.nil?
              end
          end
        end
      end
    end
  end
end

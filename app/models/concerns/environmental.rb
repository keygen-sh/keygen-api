# frozen_string_literal: true

module Environmental
  extend ActiveSupport::Concern

  included do
    include Dirtyable

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
                    when UUID_RE
                      Environment.find(environment)
                    else
                      environment
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
    def has_environment(default: nil)
      belongs_to :environment,
        optional: true

      tracks_dirty_attributes :environment_id,
                              :environment

      before_create -> { self.environment ||= Current.environment },
        unless: -> { environment_id_attribute_assigned? || environment_attribute_assigned? },
        if: -> { new_record? }

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
        # NOTE(ezekg) This before validation hook is in addition to the default hook above.
        before_create -> {
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
          unless: -> { environment_id_attribute_assigned? || environment_attribute_assigned? },
          if: -> { new_record? }
      end

      # We also want to assert that the model's current environment is compatible
      # with all of its :belongs_to associations that are environmental.
      unless (reflections = reflect_on_all_associations(:belongs_to)).empty?
        reflections.reject { _1.name == :environment }
                   .each do |reflection|
          # Assert that we're either we're dealing with a polymorphic association (and in that
          # case, we'll perform the environment assert later during validation), or we want
          # to assert the :belongs_to has an :environment association to assert against.
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
            errors.add :environment, :not_allowed, message: "environment must be compatible with #{reflection.name} environment" unless
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

# frozen_string_literal: true

module Environmental
  extend ActiveSupport::Concern

  included do
    cattr_accessor :inherits_environment_from,
      default: nil

    belongs_to :environment,
      optional: true

    after_initialize -> { self.environment_id ||= default_environment_id },
      if: -> {
        has_attribute?(:environment_id) && new_record?
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

    # We also want to assert that the model's environment matches the environment
    # of the association it inherits an environment from (if any).
    validate on: %i[create] do
      assoc = association_for_inherited_environment
      next if
        assoc.nil?

      errors.add :environment, :not_allowed, message: "must be compatible with #{assoc.name.underscore.humanize(capitalize: false)}'s environment" unless
        case
        when environment.nil?
          assoc.environment.nil?
        when environment.isolated?
          assoc.environment_id == environment_id
        when environment.shared?
          assoc.environment_id == environment_id || assoc.environment_id.nil?
        end
    end

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

    def association_for_inherited_environment
      return if
        inherits_environment_from.nil?

      reflection = self.class.reflect_on_association(inherits_environment_from)
      return if
        reflection.nil?

      public_send(reflection.name)
    end

    def default_environment    = Current.environment || association_for_inherited_environment&.environment
    def default_environment_id = default_environment&.id
  end

  class_methods do
    def has_environment(inherits_from: nil)
      self.inherits_environment_from = inherits_from
    end
  end
end

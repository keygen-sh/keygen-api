# frozen_string_literal: true

module Environmental
  extend ActiveSupport::Concern

  included do
    belongs_to :environment,
      optional: true

    after_initialize -> { self.environment ||= Current.environment },
      if: -> {
        has_attribute?(:environment_id) && new_record?
      }

    # TODO(ezekg) Extract this into a concern or an attr_immutable lib?
    validate on: %i[update] do
      next unless
        environment_id_changed? && environment_id != environment_id_was

      errors.add(:environment, :not_allowed, message: 'is immutable')
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
  end
end

# frozen_string_literal: true

module Environmental
  extend ActiveSupport::Concern

  included do
    belongs_to :environment,
      optional: true

    ##
    # for_environment scopes the current resource to an environment.
    #
    # When :strict is false, some environments may bleed into others. For example,
    # a shared environment may include resources from the global environment, and
    # the global environment will include resources from all environments. To
    # scope to a specific environment without others bleeding into the
    # results, enable :strict mode.
    scope :for_environment, -> environment, strict: false {
      case
      when environment.nil?
        if strict
          where(environment: nil)
        else
          self
        end
      when environment.isolated?
        where(environment:)
      when environment.shared?
        if strict
          where(environment:)
        else
          where(environment: [nil, environment])
        end
      else
        none
      end
    }
  end
end

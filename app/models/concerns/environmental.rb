# frozen_string_literal: true

module Environmental
  extend ActiveSupport::Concern

  included do
    belongs_to :environment,
      optional: true

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

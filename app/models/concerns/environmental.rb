# frozen_string_literal: true

module Environmental
  extend ActiveSupport::Concern

  included do
    belongs_to :environment,
      optional: true

    scope :for_environment, -> environment {
      case
      when environment.nil?
        where(environment: nil)
      when environment.isolated?
        where(environment:)
      when environment.shared?
        where(environment: [nil, environment])
      else
        none
      end
    }
  end
end

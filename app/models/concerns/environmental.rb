# frozen_string_literal: true

module Environmental
  extend ActiveSupport::Concern

  included do
    belongs_to :environment,
      optional: true

    scope :for_environment, -> environment {
      case environment
      in isolation_strategy: 'ISOLATED'
        where(environment:)
      in isolation_strategy: 'SHARED'
        where(environment: [nil, environment])
      else
        self
      end
    }
  end
end

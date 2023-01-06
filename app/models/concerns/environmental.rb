# frozen_string_literal: true

module Environmental
  extend ActiveSupport::Concern

  included do
    belongs_to :environment,
      optional: true

    scope :for_environments, -> *environments { where(environment: environments) }
    scope :for_environment,  -> environment   { where(environment:) }
  end
end

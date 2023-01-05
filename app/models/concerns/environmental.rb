# frozen_string_literal: true

module Environmental
  extend ActiveSupport::Concern

  included do
    belongs_to :environment,
      optional: true

    default_scope -> {
      next self unless
        Keygen.server?

      # NOTE(ezekg) We'll show all resources without an environment as well
      #             as resources for the current environment.
      where(environment: [nil, Current.environment])
    }
  end
end

module Sluggable
  extend ActiveSupport::Concern

  EXCLUDED_SLUGS = %w[actions action].freeze

  included do
    # Redefine finder to search by slug and id
    def self.find(id)
      where(slug: id).or(where(id: id)).first or super
    end
  end
end

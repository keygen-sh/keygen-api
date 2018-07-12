module Sluggable
  extend ActiveSupport::Concern

  EXCLUDED_SLUGS = %w[actions action].freeze

  included do
    # Redefine finder to search by slug and id
    def self.find(id)
      record = where(id: id).or(where(slug: id&.downcase)).first
      if record.nil?
        raise ActiveRecord::RecordNotFound
      end

      record
    end
  end
end

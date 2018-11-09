module Sluggable
  extend ActiveSupport::Concern

  EXCLUDED_SLUGS = %w[actions action].freeze

  included do
    # Redefine finder to search by slug and id
    def self.find(id)
      raise ActiveRecord::RecordNotFound if id.nil?

      # FIXME(ezekg) Decouple this from the account model
      scope = includes :billing
      record =
        if id =~ UUID_REGEX
          scope.find_by id: id
        else
          scope.find_by slug: id.downcase
        end

      if record.nil?
        raise ActiveRecord::RecordNotFound
      end

      record
    end
  end
end

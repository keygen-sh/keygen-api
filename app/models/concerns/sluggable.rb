module Sluggable
  extend ActiveSupport::Concern

  included do
    # Redefine finder to search by slug and id
    def self.find(id)
      where(slug: id).or(where(id: id)).first or super
    end
  end
end

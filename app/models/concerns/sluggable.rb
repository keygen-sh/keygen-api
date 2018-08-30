module Sluggable
  extend ActiveSupport::Concern

  EXCLUDED_SLUGS = %w[actions action].freeze

  included do
    # Redefine finder to search by slug and id
    def self.find(id)
      raise ActiveRecord::RecordNotFound if id.nil?

      # FIXME(ezekg) Decouple this from the account model
      record = includes(:billing)
                 .where(
                   'accounts.id = :id OR accounts.slug = :slug',
                    id: id =~ UUID_REGEX ? id : nil,
                    slug: id.downcase
                  )
                 .first

      if record.nil?
        raise ActiveRecord::RecordNotFound
      end

      record
    end
  end
end

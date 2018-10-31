module Sluggable
  extend ActiveSupport::Concern

  EXCLUDED_SLUGS = %w[actions action].freeze

  included do
    # Redefine finder to search by slug and id
    def self.find(account_id)
      raise ActiveRecord::RecordNotFound if account_id.nil?

      # FIXME(ezekg) Decouple this from the account model
      if account_id =~ UUID_REGEX
        id = account_id
      else
        slug = account_id.downcase
      end

      record = includes(:billing)
                 .where(
                   'accounts.id = :id OR accounts.slug = :slug',
                    id: id,
                    slug: slug
                  )
                 .first

      if record.nil?
        raise ActiveRecord::RecordNotFound
      end

      record
    end
  end
end

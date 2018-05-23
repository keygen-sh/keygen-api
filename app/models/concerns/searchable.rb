module Searchable
  extend ActiveSupport::Concern

  included do
    include PgSearch

    def self.search(attributes:, relationships: {})
      attributes.each do |attribute|
        pg_search_scope "search_#{attribute}",
          against: attribute,
          using: {
            tsearch: {
              dictionary: 'simple',
              any_word: true,
              prefix: true
            }
          }
      end

      # I believe it will be impossible to speed up these searches with database
      # indexes. May want to revisit this in the future, as it is very slow.
      relationships.each do |relationship, attributes|
        pg_search_scope "search_#{relationship}",
          associated_against: {
            relationship => attributes
          },
          using: {
            tsearch: {
              any_word: true,
              prefix: true
            }
          }
      end
    end
  end
end
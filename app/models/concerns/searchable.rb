module Searchable
  extend ActiveSupport::Concern

  included do
    include PgSearch

    def self.search(attributes:, relationships: {})
      attributes.each do |attribute|
        pg_search_scope "search_#{attribute}", against: attribute
      end
      relationships.each do |relationship, attributes|
        pg_search_scope "search_#{relationship}", associated_against: {
          relationship => attributes
        }
      end
    end
  end
end
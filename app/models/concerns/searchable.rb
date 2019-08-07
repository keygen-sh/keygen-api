# frozen_string_literal: true

module Searchable
  extend ActiveSupport::Concern

  included do
    include PgSearch::Model

    def self.search(attributes:, relationships: {})
      attributes.each do |attribute|
        scope, against = nil

        case attribute
        when Hash
          scope, against = attribute.first
        when Symbol
          scope = against = attribute
        else
          throw InvalidSearchAttribute.new("invalid search attribute type '#{attribute.class.name.underscore}' for '#{self.name.underscore}'")
        end

        # Skip prefix search on metadata
        prefix =
          against != :metadata

        pg_search_scope "search_#{scope}",
          against: against,
          using: {
            tsearch: {
              dictionary: 'simple',
              prefix: prefix
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
              prefix: false
            }
          }
      end
    end
  end

  class InvalidSearchAttribute < StandardError; end
end
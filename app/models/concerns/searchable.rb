module Searchable
  extend ActiveSupport::Concern

  included do
    include PgSearch

    def self.search(attributes:, relationships: {}, &block)
      attributes.each do |attribute|
        scope, against = nil

        # Apply transformations
        attribute = yield attribute if block_given?

        case attribute
        when Hash
          scope, against = attribute.first
        when Symbol
          scope = against = attribute
        else
          throw InvalidSearchAttribute.new("invalid search attribute type '#{attribute.class.name.underscore}' for '#{self.class.name.underscore}")
        end

        pg_search_scope "search_#{scope}",
          against: against,
          using: {
            tsearch: {
              dictionary: 'simple',
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
              prefix: true
            }
          }
      end
    end
  end

  class InvalidSearchAttribute < StandardError; end
end
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

        pg_search_scope "search_#{scope}", lambda { |query|
          case
          when against == :email
            # Remove `@` so that searching on partial email is doable e.g. `User.search_email('@keygen.sh')`
            query = query.gsub('@', ' ')
          when scope == :fuzzy
            # Remove `/` so that searching on partial URL is doable e.g. `RequestLog.search_fuzzy('/validate-key')`
            query = query.gsub('/', ' ')
          end

          # Skip prefix search on metadata
          prefix = true

          if against == :metadata
            prefix = false

            # Transform keys to snakecase (may be camelcased user input) and then
            # map into string query parts
            if query.respond_to?(:transform_keys!)
              query = query.transform_keys { |k| k.to_s.underscore.parameterize(separator: '_') }
                           .map { |k, v| "#{k}:#{v}" }
            end
          end

          {
            against: against,
            query: query,
            using: {
              tsearch: {
                dictionary: 'simple',
                prefix: prefix,
              }
            }
          }
        }
      end

      # I believe it will be impossible to speed up these searches with database
      # indexes. May want to revisit this in the future, as it is very slow.
      relationships.each do |relationship, attributes|
        pg_search_scope "search_#{relationship}", lambda { |query|
          query = query.gsub('@', ' ') if attributes.include?(:email)

          {
            associated_against: { relationship => attributes },
            query: query,
            using: {
              tsearch: {
                dictionary: 'simple',
                prefix: false,
              }
            }
          }
        }
      end
    end
  end

  class InvalidSearchAttribute < StandardError; end
end
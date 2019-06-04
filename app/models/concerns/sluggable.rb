module Sluggable
  extend ActiveSupport::Concern

  EXCLUDED_SLUGS = %w[actions action].freeze

  included do
    @sluggable_attributes = %i[id]
    @sluggable_scope = nil
    @sluggable_model = nil

    class << self
      attr_accessor :sluggable_attributes
      attr_accessor :sluggable_scope
      attr_accessor :sluggable_model

      def sluggable(attributes:, scope: nil, association_base_model: nil)
        @sluggable_attributes = attributes
        @sluggable_scope = scope
        @sluggable_model = association_base_model ||
                           self.name

        # Support for sluggable finders on associations and collection proxies
        if Object.const_defined? "#{self.name}::ActiveRecord_AssociationRelation"
          delegate = "#{self.name}::ActiveRecord_AssociationRelation".constantize

          delegate.send(:include, Sluggable)
          delegate.send(:sluggable, attributes: attributes, scope: scope, association_base_model: self.name)
        end

        if Object.const_defined? "#{self.name}::ActiveRecord_Associations_CollectionProxy"
          delegate = "#{self.name}::ActiveRecord_Associations_CollectionProxy".constantize

          delegate.send(:include, Sluggable)
          delegate.send(:sluggable, attributes: attributes, scope: scope, association_base_model: self.name)
        end
      end

      # Redefine finder to search by sluggable attributes
      def find(slug, scope: self)
        raise Keygen::Error::NotFoundError.new(model: sluggable_model, id: slug) if slug.nil?

        # Strip out ID attribute if the finder doesn't resemble a UUID (pg will throw)
        attrs = sluggable_attributes.dup
        attrs.reject! { |a| a == :id } unless slug =~ UUID_REGEX

        if attrs.empty?
          raise Keygen::Error::NotFoundError.new(model: sluggable_model, id: slug)
        end

        scope =
          if sluggable_scope.respond_to?(:call)
            sluggable_scope.call(scope)
          else
            scope
          end

        # Generates a query resembling the following:
        #
        #   SELECT
        #     *
        #   FROM
        #     accounts
        #   WHERE
        #     id   = :slug OR
        #     slug = :slug
        record = scope
          .where(
            attrs.map { |a| "#{a} = :slug" }.join(" OR "),
            slug: slug
          )
          .limit(1)
          .first

        if record.nil?
          raise Keygen::Error::NotFoundError.new(model: sluggable_model, id: slug)
        end

        record
      end
    end

    # Relations and collection proxies need to delegate to the
    # class's finder method
    def find(slug)
      self.class.find(slug, scope: self)
    end
  end
end

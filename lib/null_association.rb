# frozen_string_literal: true

module NullAssociation
  class NullObject
    def nil?                            = true # considered nil when asked
    def respond_to_method_missing?(...) = true # respond to everything
    def method_missing(...)             = nil
  end

  module Macro
    extend ActiveSupport::Concern

    class_methods do
      def belongs_to(name, scope = nil, null_object: nil, **options, &extension)
        return super(name, scope, **options, &extension) if null_object.nil?

        unless options[:optional]
          raise ArgumentError, 'must be :optional to use :null_object'
        end

        super(name, scope, **options, &extension)

        null_class = case null_object
                     in Class => klass
                       klass
                     in String => class_name
                       class_name.classify.constantize
                     else
                       raise ArgumentError, 'invalid :null_object (expected class or string)'
                     end

        define_method name do
          super().presence || null_class.new
        end
      end

      def has_one(name, scope = nil, null_object: nil, **options, &extension)
        return super(name, scope, **options, &extension) if null_object.nil?

        super(name, scope, **options, &extension)

        null_class = case null_object
                     in Class => klass
                       klass
                     in String => class_name
                       class_name.classify.constantize
                     else
                       raise ArgumentError, 'invalid :null_object (expected class or string)'
                     end

        define_method name do
          super().presence || null_class.new
        end
      end
    end
  end
end

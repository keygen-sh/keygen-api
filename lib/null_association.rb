# frozen_string_literal: true

module NullAssociation
  module Macro
    extend ActiveSupport::Concern

    class_methods do
      def belongs_to(name, scope = nil, null_object: nil, **options, &extension)
        return super(name, scope, **options, &extension) if null_object.nil?

        unless options[:optional]
          raise ArgumentError, 'must be :optional to use :null_object'
        end

        super(name, scope, **options, &extension)

        define_method name do
          super().presence || to_null_object(null_object)
        end
      end

      def has_one(name, scope = nil, null_object: nil, **options, &extension)
        return super(name, scope, **options, &extension) if null_object.nil?

        super(name, scope, **options, &extension)

        define_method name do
          super().presence || to_null_object(null_object)
        end
      end
    end

    included do
      def to_null_object(null_object)
        case null_object
        in String => class_name
          class_name.classify.constantize.new
        in Class => klass if klass < Singleton
          klass.instance
        in Singleton => singleton
          singleton
        in Class => klass
          klass.new
        in Object => instance
          instance
        else
          nil
        end
      end
    end
  end
end

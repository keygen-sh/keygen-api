# frozen_string_literal: true

module NullAssociation
  module Decorator
    extend self

    def [](association_name, null_object: nil)
      Module.new do
        define_method association_name do
          super().presence || case null_object
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

  module Concern
    extend ActiveSupport::Concern

    class_methods do
      def belongs_to(name, scope = nil, null_object: nil, **options, &extension)
        return super(name, scope, **options, &extension) if null_object.nil?

        unless options[:optional]
          raise ArgumentError, 'must be :optional to use :null_object'
        end

        # generate getter
        super(name, scope, **options, &extension)

        # decorate getter
        include Decorator[name, null_object:]
      end

      def has_one(name, scope = nil, null_object: nil, **options, &extension)
        return super(name, scope, **options, &extension) if null_object.nil?

        # generate getter
        super(name, scope, **options, &extension)

        # decorate getter
        include Decorator[name, null_object:]
      end
    end
  end
end

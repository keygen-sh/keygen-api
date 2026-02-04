# frozen_string_literal: true

module Keygen
  module EE
    class ProtectedMethodError < StandardError; end

    module ProtectedMethods
      class Protector
        attr_reader :protection_module

        def initialize(name:, protection_module: nil)
          @protection_module = protection_module || Module.new do
            class << self
              attr_accessor :protected_method_names, # NB(ezekg) avoids overloading native protected_methods
                            :name

              def inspect = "#{super}(#{protected_method_names.join(', ')})"
            end

            self.protected_method_names = []
            self.name = name
          end
        end

        def add_singleton_method(method_name, entitlements:)
          return if protection_module.method_defined?(method_name)

          protection_module.protected_method_names << method_name
          protection_module.define_method(method_name) do |*args, **kwargs, &block|
            raise ProtectedMethodError, "Calling #{name}.#{method_name} is not available in Keygen CE. Please upgrade to Keygen EE." if
              Keygen.ce?

            raise ProtectedMethodError, "Calling #{name}.#{method_name} is not allowed. Please upgrade Keygen EE." unless
              Keygen.ee { |key, lic| lic.valid? && key.valid? && key.entitled?(*entitlements) }

            super(*args, **kwargs, &block)
          end
        end

        def add_instance_method(method_name, entitlements:)
          return if protection_module.method_defined?(method_name)

          protection_module.protected_method_names << method_name
          protection_module.define_method(method_name) do |*args, **kwargs, &block|
            raise ProtectedMethodError, "Calling #{self.class.name}##{method_name} is not available in Keygen CE. Please upgrade to Keygen EE." if
              Keygen.ce?

            raise ProtectedMethodError, "Calling #{self.class.name}##{method_name} is not allowed. Please upgrade Keygen EE." unless
              Keygen.ee { |key, lic| lic.valid? && key.valid? && key.entitled?(*entitlements) }

            super(*args, **kwargs, &block)
          end
        end

        def prepend_to(target)
          target.prepend(protection_module) unless target < protection_module
        end
      end

      class Bouncer
        PROTECTED_SINGLETON_METHODS_MODULE_NAME = :ProtectedSingletonMethods
        PROTECTED_INSTANCE_METHODS_MODULE_NAME  = :ProtectedInstanceMethods

        def initialize(klass:, entitlements:)
          @klass        = klass
          @entitlements = entitlements
        end

        def protect_singleton_methods!(method_names)
          protector = find_or_create_method_protector(name: PROTECTED_SINGLETON_METHODS_MODULE_NAME)

          method_names.each do |method_name|
            protector.add_singleton_method(method_name, entitlements:)
          end

          protector.prepend_to(klass.singleton_class)
        end

        def protect_instance_methods!(method_names)
          protector = find_or_create_method_protector(name: PROTECTED_INSTANCE_METHODS_MODULE_NAME)

          method_names.each do |method_name|
            protector.add_instance_method(method_name, entitlements:)
          end

          protector.prepend_to(klass)
        end

        private

        attr_reader :klass, :entitlements

        def find_or_create_method_protector(name:)
          if klass.const_defined?(name, false)
            protection_module = klass.const_get(name, false)

            return Protector.new(name:, protection_module:)
          end

          protector = Protector.new(name:)

          # this allows us to keep all protections under a single module
          klass.const_set(name, protector.protection_module)

          protector
        end
      end

      def self.[](*methods, singleton_methods: methods, instance_methods: methods, entitlements: [])
        raise ArgumentError, 'cannot use both positional and keyword arguments for methods' if
          methods.any? && (singleton_methods != methods || instance_methods != methods)

        raise ArgumentError, 'must provide at least 1 method' if
          singleton_methods.empty? && instance_methods.empty?

        Module.new do
          next unless
            Keygen.console? # we only want to run protections in console

          define_singleton_method :included do |klass|
            bouncer = Bouncer.new(klass:, entitlements:)

            unless singleton_methods.empty?
              bouncer.protect_singleton_methods!(singleton_methods)
            end

            unless instance_methods.empty?
              bouncer.protect_instance_methods!(instance_methods)
            end
          end

          define_singleton_method :prepended do |klass|
            included klass
          end
        end
      end

      def self.prepended(klass)
        raise NotImplementedError, 'must be included like ProtectedMethods[...]'
      end

      def self.included(klass)
        raise NotImplementedError, 'must be included like ProtectedMethods[...]'
      end
    end
  end
end

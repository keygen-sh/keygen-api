module Keygen
  module EE
    class ProtectedMethodError < StandardError; end

    module ProtectedMethods
      class MethodProxy
        def initialize(singleton_methods:, instance_methods:)
          @proxied_singleton_methods = singleton_methods.reduce({}) { |h, v| h.merge(v => false) }
          @proxied_instance_methods  = instance_methods.reduce({}) { |h, v| h.merge(v => false) }
        end

        def run_protected_singleton_method(method, *args, **kwargs)
          raise ProtectedMethodError, "Calling #{method.owner.name}.#{method.name} is not available in Keygen CE. Please upgrade to Keygen EE." if
            Keygen.console? && Keygen.ce?

          method.call(*args, **kwargs)
        end

        def run_protected_instance_method(method, *args, **kwargs)
          raise ProtectedMethodError, "Calling #{method.owner.name}##{method.name} is not available in Keygen CE. Please upgrade to Keygen EE." if
            Keygen.console? && Keygen.ce?

          method.call(*args, **kwargs)
        end

        def protected_singleton_method?(method)
          @proxied_singleton_methods.key?(method)
        end

        def protected_instance_method?(method)
          @proxied_instance_methods.key?(method)
        end

        def proxied_singleton_method?(method)
          @proxied_singleton_methods.fetch(method) { false }
        end

        def proxied_instance_method?(method)
          @proxied_instance_methods.fetch(method) { false }
        end

        def proxied_singleton_method!(method)
          raise ArgumentError, "method #{method} is not a protected method" unless
            protected_singleton_method?(method)

          raise ArgumentError, "method #{method} is already proxied" if
            proxied_singleton_method?(method)

          @proxied_singleton_methods[method] = true
        end

        def proxied_instance_method!(method)
          raise ArgumentError, "method #{method} is not a protected method" unless
            protected_instance_method?(method)

          raise ArgumentError, "method #{method} is already proxied" if
            proxied_instance_method?(method)

          @proxied_instance_methods[method] = true
        end
      end

      module MethodBouncer
        def instrument_protected_methods!(singleton_methods:, instance_methods:)
          @protected_method_proxy ||= MethodProxy.new(
            singleton_methods:,
            instance_methods:,
          )
        end

        private

        def singleton_method_added(method)
          proxy = @protected_method_proxy

          return super unless
            proxy.protected_singleton_method?(method)

          return super if
            proxy.proxied_singleton_method?(method)

          original_method = method(method)

          proxy.proxied_singleton_method!(method)

          define_singleton_method method do |*args, **kwargs|
            bound_method = original_method.bind(self)

            proxy.run_protected_singleton_method(
              bound_method,
              *args,
              **kwargs,
            )
          end

          super
        end

        def method_added(method)
          proxy = @protected_method_proxy

          return super unless
            proxy.protected_instance_method?(method)

          return super if
            proxy.proxied_instance_method?(method)

          original_method = instance_method(method)

          proxy.proxied_instance_method!(method)

          define_method method do |*args, **kwargs|
            bound_method = original_method.bind(self)

            proxy.run_protected_instance_method(
              bound_method,
              *args,
              **kwargs,
            )
          end

          super
        end
      end

      def self.[](*methods, singleton_methods: methods, instance_methods: methods)
        raise ArgumentError, 'cannot use both positional and keyword arguments' if
          methods.any? && singleton_methods != methods ||
                          instance_methods != methods

        Module.new do
          define_singleton_method :included do |klass|
            klass.extend MethodBouncer

            klass.instrument_protected_methods!(
              singleton_methods:,
              instance_methods:,
            )
          end
        end
      end
    end
  end
end

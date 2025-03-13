module Keygen
  module EE
    class ProtectedMethodError < StandardError; end

    module ProtectedMethods
      class MethodProxy
        attr_reader :singleton_methods,
                    :instance_methods,
                    :entitlements

        def initialize(singleton_methods:, instance_methods:, entitlements:)
          @proxied_singleton_methods = singleton_methods.reduce({}) { |h, v| h.merge(v => nil) }
          @proxied_instance_methods  = instance_methods.reduce({}) { |h, v| h.merge(v => nil) }
          @singleton_methods         = singleton_methods
          @instance_methods          = instance_methods
          @entitlements              = entitlements
        end

        def run_protected_singleton_method(method, ...)
          raise ProtectedMethodError, "Calling #{method.receiver.name}.#{method.name} is not available in Keygen CE. Please upgrade to Keygen EE." if
            Keygen.ce?

          raise ProtectedMethodError, "Calling #{method.receiver.name}.#{method.name} is not allowed. Please upgrade Keygen EE." unless
            Keygen.ee { |key, lic|
              lic.valid? && key.valid? && key.entitled?(*entitlements)
            }

          method.call(...)
        end

        def run_protected_instance_method(method, ...)
          raise ProtectedMethodError, "Calling #{method.receiver.class.name}##{method.name} is not available in Keygen CE. Please upgrade to Keygen EE." if
            Keygen.ce?

          raise ProtectedMethodError, "Calling #{method.receiver.class.name}##{method.name} is not allowed. Please upgrade Keygen EE." unless
            Keygen.ee { |key, lic|
              lic.valid? && key.valid? && key.entitled?(*entitlements)
            }

          method.call(...)
        end

        def protected_singleton_method?(method)
          proxied_singleton_methods.key?(method.name)
        end

        def protected_instance_method?(method)
          proxied_instance_methods.key?(method.name)
        end

        def proxied_singleton_method?(method)
          proxied_singleton_methods[method.name] == method
        end

        def proxied_instance_method?(method)
          proxied_instance_methods[method.name] == method
        end

        def proxy_singleton_method!(method)
          raise ArgumentError, "method #{method} is not a protected method" unless
            protected_singleton_method?(method)

          proxied_singleton_methods[method.name] = method
        end

        def proxy_instance_method!(method)
          raise ArgumentError, "method #{method} is not a protected method" unless
            protected_instance_method?(method)

          proxied_instance_methods[method.name] = method
        end

        private

        attr_reader :proxied_singleton_methods,
                    :proxied_instance_methods
      end

      module MethodBouncer
        def instrument_protected_methods!(singleton_methods:, instance_methods:, entitlements:)
          @protected_singleton_methods = [*@protected_singleton_methods, *singleton_methods]
          @protected_instance_methods  = [*@protected_instance_methods, *instance_methods]
          @protected_method_proxies    = [
            *@protected_method_proxies,
            MethodProxy.new(
              singleton_methods:,
              instance_methods:,
              entitlements:,
            ),
          ]

          protect_singleton_methods!
          protect_instance_methods!
        end

        private

        ##
        # protect_singleton_methods! decorates singleton methods added before our module was included.
        def protect_singleton_methods!
          @protected_method_proxies.each do |proxy|
            proxy.singleton_methods.each do |method_name|
              next unless
                singleton_methods.include?(method_name)

              method = method(method_name)
              next unless
                proxy.protected_singleton_method?(method)

              redefine_singleton_method(method_name) do |*args, **kwargs|
                proxy.run_protected_singleton_method(
                  method,
                  *args,
                  **kwargs,
                )
              end
            end
          end
        end

        ##
        # protect_instance_methods! decorates instance methods added before our module was included.
        def protect_instance_methods!
          @protected_method_proxies.each do |proxy|
            proxy.instance_methods.each do |method_name|
              next unless
                instance_methods.include?(method_name)

              method = instance_method(method_name)
              next unless
                proxy.protected_instance_method?(method)

              redefine_instance_method(method_name) do |*args, **kwargs|
                bound_method = method.bind(self)

                proxy.run_protected_instance_method(
                  bound_method,
                  *args,
                  **kwargs,
                )
              end
            end
          end
        end

        ##
        # singleton_method_added decorates singleton methods added after our module has been included.
        def singleton_method_added(method_name)
          method = method(method_name)
          return super unless
            method.present?

          @protected_method_proxies.each do |proxy|
            next unless
              proxy.protected_singleton_method?(method)

            next if
              proxy.proxied_singleton_method?(method)

            proxy.proxy_singleton_method!(
              redefine_singleton_method(method_name) { |*args, **kwargs|
                proxy.run_protected_singleton_method(
                  method,
                  *args,
                  **kwargs,
                )
              },
            )
          end

          super
        end

        ##
        # method_added decorates instance methods added after our module has been included.
        def method_added(method_name)
          method = instance_method(method_name)
          return super unless
            method.present?

          @protected_method_proxies.each do |proxy|
            next unless
              proxy.protected_instance_method?(method)

            next if
              proxy.proxied_instance_method?(method)

            proxy.proxy_instance_method!(
              redefine_instance_method(method_name) { |*args, **kwargs|
                bound_method = method.bind(self)

                proxy.run_protected_instance_method(
                  bound_method,
                  *args,
                  **kwargs,
                )
              },
            )
          end

          super
        end

        ##
        # redefine_singleton_method allows a non-cylic redefinition of a singleton method.
        def redefine_singleton_method(method_name, &)
          @_singleton_methods ||= {}

          return method(method_name) if
            @_singleton_methods[method_name]

          begin
            @_singleton_methods[method_name] = true

            define_singleton_method(method_name, &)
          ensure
            @_singleton_methods[method_name] = false
          end

          method(method_name)
        end

        ##
        # redefine_instance_method allows a non-cylic redefinition of an instance method.
        def redefine_instance_method(method_name, &)
          @_instance_methods ||= {}

          return instance_method(method_name) if
            @_instance_methods[method_name]

          begin
            @_instance_methods[method_name] = true

            define_method(method_name, &)
          ensure
            @_instance_methods[method_name] = false
          end

          instance_method(method_name)
        end
      end

      def self.[](*methods, singleton_methods: methods, instance_methods: methods, entitlements: [])
        raise ArgumentError, 'cannot use both positional and keyword arguments for methods' if
          methods.any? && (singleton_methods != methods || instance_methods != methods)

        raise ArgumentError, 'must provide at least 1 method' if
          singleton_methods.empty? && instance_methods.empty?

        Module.new do
          next unless
            Keygen.console?

          define_singleton_method :included do |klass|
            # NOTE(ezekg) make sure all attr methods are defined since we can't hook them via method_added
            klass.define_attribute_methods if klass.respond_to?(:define_attribute_methods)

            klass.extend MethodBouncer

            klass.instrument_protected_methods!(
              singleton_methods:,
              instance_methods:,
              entitlements:,
            )
          end
        end
      end

      def self.included(klass)
        raise NotImplementedError, 'must be included like ProtectedMethods[...]'
      end
    end
  end
end

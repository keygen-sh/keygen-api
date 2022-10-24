# frozen_string_literal: true

module Keygen
  module EE
    class ProtectedRecordError < StandardError; end

    module ProtectedRecord
      QUERYING_METHODS = [
        *ActiveRecord::Querying::QUERYING_METHODS,
        :find_by_sql,
        :async_find_by_sql,
        :count_by_sql,
        :async_find_by_sql,
        :all,
      ].freeze

      module RecordBouncer
        def instrument_protected_record!(entitlements:)
          QUERYING_METHODS.each do |method|
            define_method method do |*args, **kwargs|
              raise ProtectedRecordError, "Querying #{name}.#{method} is not available in Keygen CE. Please upgrade to Keygen EE." if
                Keygen.console? && Keygen.ce?

              raise ProtectedRecordError, "Querying #{name}.#{method} is not allowed. Please upgrade Keygen EE." if
                Keygen.console? && Keygen.ee { !_1.entitled?(*entitlements) }

              super(*args, **kwargs)
            end
          end
        end
      end

      def self.[](*methods, singleton_methods: methods, instance_methods: methods, entitlements: [])
        raise ArgumentError, 'cannot use both positional and keyword arguments' if
          methods.any? && singleton_methods != methods ||
                          instance_methods != methods

        Module.new do
          define_singleton_method :included do |klass|
            klass.extend RecordBouncer

            klass.instrument_protected_record!(
              entitlements:,
            )
          end
        end
      end
    end
  end
end

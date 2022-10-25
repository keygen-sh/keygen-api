# frozen_string_literal: true

module Keygen
  module EE
    module ProtectedRecord
      SINGLETON_METHODS = [:find_by_sql, :async_find_by_sql, :count_by_sql, :async_find_by_sql, :all, *ActiveRecord::Querying::QUERYING_METHODS].freeze
      INSTANCE_METHODS  = %i[reload].freeze

      def self.[](entitlements: [])
        Module.new do
          next unless
            Keygen.console?

          define_singleton_method :included do |klass|
            klass.include ProtectedMethods[
              singleton_methods: SINGLETON_METHODS,
              instance_methods: INSTANCE_METHODS,
              entitlements:,
            ]
          end
        end
      end

      def self.included(klass)
        klass.include ProtectedRecord[]
      end
    end
  end
end

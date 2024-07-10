# frozen_string_literal: true

module Keygen
  module Exportable
    EXPORTABLE_CLASSES = Set.new

    def self.exportable_classes = EXPORTABLE_CLASSES
    def self.included(klass)
      raise ArgumentError, "cannot be used outside of model (got #{klass.ancestors})" unless
        klass < ::ActiveRecord::Base

      EXPORTABLE_CLASSES << klass

      klass.include(Concern)
    end

    module Concern
      extend ActiveSupport::Concern

      included do
        cattr_accessor :export_callbacks, default: []
        cattr_accessor :import_callbacks, default: []

        def attributes_for_export = self.class.attributes_for_export([attributes]).sole
      end

      class_methods do
        def exports(callback) = export_callbacks << callback
        def imports(callback) = import_callbacks << callback

        def attributes_for_export(attributes)
          export_callbacks.reduce(attributes) do |attrs, callback|
            attrs.map { callback.call(_1.symbolize_keys) }
          end
        end

        def attributes_for_import(attributes)
          import_callbacks.reduce(attributes) do |attrs, callback|
            attrs.map { callback.call(_1.symbolize_keys) }
          end
        end
      end
    end
  end
end

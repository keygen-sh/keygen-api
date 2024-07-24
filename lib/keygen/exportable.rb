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
          export_callbacks.reduce(attributes.map(&:symbolize_keys)) do |attrs, callback|
            attrs.map(&callback)
          end
        end

        def attributes_for_import(attributes)
          import_callbacks.reduce(attributes.map(&:symbolize_keys)) do |attrs, callback|
            attrs.map(&callback)
          end
        end

        def import_all!(attributes)
          res = insert_all!(attributes_for_import(attributes), returning: %i[id])
          ids = res.rows.flatten

          where(id: ids).to_a
        end

        def import_all(attributes)
          res = insert_all(attributes_for_import(attributes), returning: %i[id])
          ids = res.rows.flatten

          where(id: ids).to_a
        end
      end
    end
  end
end

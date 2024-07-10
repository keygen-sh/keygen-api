# frozen_string_literal: true

module Keygen
  module Exportable
    EXPORTABLE_CLASSES = Set.new

    def self.exportable_classes = EXPORTABLE_CLASSES
    def self.included(klass)
      raise ArgumentError, "cannot be used outside of model (got #{klass.ancestors})" unless
        klass < ::ActiveRecord::Base

      EXPORTABLE_CLASSES << klass
    end

    def attributes_for_export
      attributes
    end
  end
end

# frozen_string_literal: true

module Keygen
  module Exportable
    CLASSES = Set.new

    def self.classes = CLASSES
    def self.included(klass)
      raise ArgumentError, "cannot be used outside of model (got #{klass.ancestors})" unless
        klass < ::ActiveRecord::Base

      CLASSES << klass
    end

    def attributes_for_export
      attributes
    end
  end
end

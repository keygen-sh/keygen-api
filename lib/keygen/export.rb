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

    # FIXME(ezekg) Make this overrideable via .exports with: -> { ... } to support
    #              e.g. exporting a user's role since it isn't Accountable.
    def attributes_for_export
      attributes
    end
  end

  module Export
  end
end

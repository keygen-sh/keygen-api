# frozen_string_literal: true

require_relative 'jsonapi/renderer'
require_relative 'jsonapi/errors'

module Keygen
  module JSONAPI
    class << self
      def render(*, **) = Renderer.new(**).render(*)

      def linkage_for(class_name, id)
        return if id.nil?

        type = type_for(class_name)
        return if
          type.nil?

        { type:, id: }
      end

      def type_for(class_name)
        klass = class_name.to_s.safe_constantize
        return if
          klass.nil?

        serializer = "#{klass.model_name.name}Serializer".safe_constantize
        return if
          serializer.nil?

        # FIXME(ezekg) might be best to define these elsewhere
        serializer.type_val
      end
    end
  end
end

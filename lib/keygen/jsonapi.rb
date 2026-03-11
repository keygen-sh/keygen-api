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
        class_name = class_name.to_s.constantize.model_name.name # respect model naming
        serializer = "#{class_name}Serializer".safe_constantize
        return if
          serializer.nil?

        # FIXME(ezekg) might be best to define these elsewhere
        serializer.type_val
      end
    end
  end
end

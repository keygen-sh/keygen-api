# frozen_string_literal: true

module Keygen::JSONAPI
  module Errors
    INDEX_RE = /\A\d+\z/.freeze

    class ResourceError
      attr_accessor :pointer,
                    :code,
                    :links

      def initialize(message, pointer: nil, code: nil, links: nil)
        @message = message
        @pointer = pointer
        @code    = code
        @links   = links
      end

      def title  = 'Unprocessable resource'
      def detail = @message
      def source = { pointer: @pointer }
      def links  = @links

      def to_h = { title:, detail:, code:, source:, links: }.compact_blank
      alias to_hash to_h # for json serialization

      # for uniq
      def eql?(other) = other.code == code && other.source == source
      def hash        = [code, source].hash

      def deconstruct_keys(keys) = to_h.slice(*keys)
    end

    module AsJSONAPI
      extend ActiveSupport::Concern

      included do
        def as_jsonapi(options = nil)
          resource_errors = group_by_attribute.flat_map do |key, errors|
            source, *rest =
            path          = key.to_s.gsub(/\[(\d+)\]/, '.\1') # remove brackets from indexes
                                    .split('.')
                                    .map { it.match?(INDEX_RE) ? it.to_i : it.to_sym }

            errors.map do |error|
              pointer = %i[data]

              # Build pointer
              if assoc = @base.class.reflect_on_association(source)
                pointer << :relationships << source

                unless rest.empty?
                  pointer << :data
                end

                rest.each do |value|
                  case
                  when Integer === value # index
                    pointer << value
                  when assoc.klass.reflect_on_association(value)
                    pointer << :relationships << value # embedded relationship
                  else
                    pointer << :attributes << value
                  end
                end
              else
                case source
                when :base
                  # noop since pointer already points to /data
                when :id
                  pointer << :id
                else
                  pointer << :attributes << source
                end
              end

              # Simplify and clarify validation error codes i.e. we don't need
              # to expose our validators to the world.
              prefix = source == :base ? @base.class.name.underscore : path.select { it in Symbol }.join('_')
              code   = case error.type
                       when :greater_than_or_equal_to,
                            :less_than_or_equal_to,
                            :greater_than,
                            :less_than,
                            :equal_to,
                            :other_than
                         :invalid
                       when :inclusion,
                            :exclusion
                         :not_allowed
                       when :blank
                         if pointer in [:data, :relationships, *]
                           :not_found
                         else
                           :missing
                         end
                       else
                         error.type
                       end

              ResourceError.new(error.message,
                pointer: '/' + pointer.map { it.to_s.camelize(:lower) }.join('/'),
                code: "#{prefix}_#{code}".parameterize
                                         .underscore
                                         .upcase,
              )
            end
          end

          resource_errors.uniq
        end
      end
    end
  end
end

ActiveModel::Errors.include Keygen::JSONAPI::Errors::AsJSONAPI

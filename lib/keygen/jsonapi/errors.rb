# frozen_string_literal: true

module Keygen::JSONAPI
  module Errors
    INDEX_RE = /\A\d+\z/.freeze

    class ResourceError
      attr_accessor :detail,
                    :title,
                    :code,
                    :source,
                    :links

      def initialize(detail, title: 'Unprocessable resource', code: nil, source: nil, links: nil)
        @detail  = detail
        @title   = title
        @code    = code
        @source  = source
        @links   = links
      end

      def to_h = { title:, detail:, code:, source:, links: }.compact_blank
      alias to_hash to_h # for json serialization

      # for uniq
      def eql?(other) = other.code == code && other.source == source
      def hash        = [code, source].hash

      def deconstruct_keys(keys) = to_h.slice(*keys)
    end

    class Serializer
      def initialize(record, errors, sources: {})
        @record  = record
        @errors  = errors
        @sources = sources
      end

      def to_pointer(**)
        pointers = @sources.fetch(:pointers, {})

        serialize_each do |source, attributes, path, error|
          pointer = pointers.fetch(source) { build_pointer(source, attributes) }
          code    = build_error_code(error, source:, path:, pointer:)

          ResourceError.new(error.message,
            source: { pointer: },
            code:,
            **,
          )
        end
      end

      def to_parameter(**)
        parameters = @sources.fetch(:parameters, {})

        serialize_each do |source, _, _, error|
          parameter = parameters.fetch(source) { source.to_s.camelize(:lower) }

          ResourceError.new(error.message,
            source: { parameter: },
            **,
          )
        end
      end

      def to_default(**)
        serialize_each do |_, _, _, error|
          ResourceError.new(error.message, **)
        end
      end

      private

      def serialize_each(&)
        resource_errors = @errors.group_by_attribute.flat_map do |key, errors|
          source, *attributes =
          path                = key.to_s.gsub(/\[(\d+)\]/, '.\1') # remove brackets from indexes
                                        .split('.')
                                        .map { it.match?(INDEX_RE) ? it.to_i : it.to_sym }

          errors.map do |error|
            yield source, attributes, path, error
          end
        end

        resource_errors.uniq
      end

      def build_pointer(source, attributes)
        pointer = %i[data]

        if @record.class.respond_to?(:reflect_on_association) && (assoc = @record.class.reflect_on_association(source))
          pointer << :relationships << source

          unless attributes.empty?
            pointer << :data
          end

          attributes.each do |value|
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

        # transform into a proper JSON pointer
        '/' + pointer.map { it.to_s.camelize(:lower) }.join('/')
      end

      # simplify and clarify validation error codes i.e. we don't need
      # to expose most of our validator names to the world
      def build_error_code(error, source: nil, path: [], pointer: nil)
        prefix = source == :base ? @record.class.name.underscore : path.select { it in Symbol }.join('_')
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
                   if pointer in %r{^/data/relationships/}
                     :not_found
                   else
                     :missing
                   end
                 else
                   error.type
                 end

        "#{prefix}_#{code}".parameterize.underscore.upcase
      end
    end

    module AsJSONAPI
      extend ActiveSupport::Concern

      included do
        def as_jsonapi(source: :pointer, sources: {}, **)
          serializer = Serializer.new(@base, self, sources:)

          case source
          when :pointer   then serializer.to_pointer(**)
          when :parameter then serializer.to_parameter(**)
          else                 serializer.to_default(**)
          end
        end
      end
    end
  end
end

ActiveModel::Errors.include Keygen::JSONAPI::Errors::AsJSONAPI

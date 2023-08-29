# frozen_string_literal: true

module Keygen::JSONAPI
  # FIXME(ezekg) There are a lot of hacky workarounds here, e.g. treating relationships
  #              as attributes, etc. Would love to clean things up and make it less
  #              dependent on inside knowledge. If we hardcoded all error responses,
  #              with codes, according to pointer, that may make things cleaner.
  #              Would also make documentating all error codes easier.
  module Errors
    INDEX_RE = /\A\d+\z/.freeze

    class Error
      def initialize(message, record:, attr:, code: nil, pointer: nil, links: nil)
        @message = message
        @record  = record
        @attr    = attr
        @code    = code
        @pointer = pointer
        @links   = links
      end

      def title  = 'Unprocessable resource'
      def detail = @message
      def source = { pointer: @pointer }
      def links  = { about: }.compact_blank
      def code
        # simplify these error types
        reason = case @code
                 when :greater_than_or_equal_to, :less_than_or_equal_to,
                      :greater_than, :less_than, :equal_to, :other_than
                   :invalid
                 when :inclusion, :exclusion
                   :not_allowed
                 when :blank
                   if @pointer.starts_with?('/data/relationships')
                     :not_found
                   else
                     :missing
                   end
                 else
                   @code
                 end

        "#{attr}_#{reason}".parameterize
                           .underscore
                           .upcase
      end

      def to_h = { title:, detail:, code:, source:, links: }.compact_blank
      alias to_hash to_h

      private

      def attr
        case @attr
        when :'role.permission_ids',
             :permission_ids
          :permissions
        when :base
          @record.class.name.underscore
        else
          @attr
        end
      end

      def about
        object = @record.class.name.underscore.pluralize
        return if
          object == 'accounts'

        type = @pointer.delete_prefix('/').split('/').second
        src  = attr.to_s.camelize(:lower)

        # FIXME(ezekg) Special cases (need to update docs)
        type = 'attrs' if type == 'attributes'
        type = nil     if src == 'id'

        unless object.nil? || type.nil? || src.nil?
          "https://keygen.sh/docs/api/#{object}/##{object}-object-#{type}-#{src}"
        end
      end
    end

    module AsJSONAPI
      extend ActiveSupport::Concern

      included do
        def as_jsonapi(options = nil)
          group_by_attribute.flat_map do |key, errors|
            source, *rest = key.to_s.gsub(/\[(\d+)\]/, '.\1') # remove brackets from indexes
                                    .split('.')
                                    .map(&:to_sym)

            errors.map do |error|
              path = %i[data]

              if assoc = @base.class.reflect_on_association(source)
                case assoc.name
                # FIXME(ezekg) Define 'invisible' relationships?
                when :role
                  if rest.any? { _1 =~ /permissions?/ }
                    path << :attributes << :permissions
                  else
                    path << :attributes << :role
                  end
                when :channel
                  path << :attributes << :channel
                when :platform
                  path << :attributes << :platform
                when :arch
                  path << :attributes << :arch
                when :filetype
                  path << :attributes << :filetype
                else
                  if @base.class == Account && source == :users # FIXME(ezekg) nix?
                    path << :relationships << :admins
                  else
                    path << :relationships << source
                  end

                  unless rest.empty?
                    path << :data
                  end

                  rest.each do |value|
                    case
                    when value.match?(INDEX_RE)
                      path << value
                    when assoc.klass.reflect_on_association(value)
                      path << :relationships << value
                    else
                      path << :attributes << value
                    end
                  end
                end
              else
                case source
                when :base
                  # noop since pointer already points to /data
                when :id
                  path << :id
                when :permission_ids
                  path << :attributes << :permissions
                else
                  path << :attributes << source
                end
              end

              Error.new(error.message,
                attr: key.to_s.gsub(/\[\d+\]/, '').to_sym,
                record: @base,
                pointer: '/' + path.map { _1.to_s.camelize(:lower) }.join('/'),
                code: error.type,
              )
            end
          end
        end
      end
    end
  end
end

ActiveModel::Errors.include Keygen::JSONAPI::Errors::AsJSONAPI

# frozen_string_literal: true

require 'active_support'
require 'active_record'

module KeysetPagination
  # default paginator for models ordered by the conventional (created_at, id)
  DEFAULT_PAGINATOR = -> (scope, cursor:, size:, order:) {
    model      = scope.respond_to?(:klass) ? scope.klass : scope.class
    table_name = model.table_name

    if cursor.present?
      comparator = order == :desc ? '<' : '>'

      # NB(ezekg) we're being explicit with qualifying columns because some libs,
      #           e.g. active_record_union, don't properly name their query object,
      #           so active record can become confused, which results in ambiguous
      #           column errors raised by pg due to the unqualified columns.
      cursor_sub = scope.reselect("#{table_name}.created_at", "#{table_name}.id")
                        .where("#{table_name}.id": cursor)
                        .reorder(
                          "#{table_name}.created_at": order,
                          "#{table_name}.id": order,
                        )
                        .limit(1)

      scope = scope.where(
        "(#{table_name}.created_at, #{table_name}.id) #{comparator} (#{cursor_sub.to_sql})",
      )
    end

    scope.reorder(
            "#{table_name}.created_at": order,
            "#{table_name}.id": order,
          )
          .limit(size)
  }

  class Error < StandardError; end

  class InvalidParameterError < Error
    attr_reader :parameter

    def initialize(message = nil, parameter: nil)
      @parameter = parameter

      super(message)
    end
  end

  class Configuration
    # controls the method name used for paginating a relation
    attr_accessor :pagination_method_name

    # controls the query parameter name for paginating
    attr_accessor :pagination_param_name

    # controls the default pagination page size
    attr_accessor :default_page_size

    # controls the max pagination page size
    attr_accessor :max_page_size

    def initialize
      @pagination_method_name  = :paginate
      @pagination_param_name   = :page
      @default_page_size       = 10
      @max_page_size           = 100
    end
  end

  class << self
    def configuration = @configuration ||= Configuration.new
    def configuration=(config)
      @configuration = config
    end

    def configure
      yield configuration
    end
  end

  class Page < Module
    def initialize(unpaged:, cursor:, order:)
      super()

      define_method(:current_cursor) { cursor }
      define_method(:next_cursor)    { last&.id }

      define_method :has_more? do
        next false if next_cursor.nil?

        # peek to see if another record exists
        keyset_paginator.call(unpaged, cursor: next_cursor, size: 1, order:)
                        .exists?
      end
    end
  end

  module Model
    extend ActiveSupport::Concern

    included do
      class_attribute :keyset_paginator, instance_writer: false, default: nil
    end

    class_methods do
      def keyset_pagination? = keyset_pagination.present?
      def keyset_pagination(&paginator)
        self.keyset_paginator = paginator || DEFAULT_PAGINATOR
      end
    end

    def self.included(klass)
      config = KeysetPagination.configuration

      super

      # wire up default keyset pagination scope
      klass.keyset_pagination

      klass.scope config.pagination_method_name, -> (cursor: nil, size: nil, order: :desc) {
        cursor = cursor.presence
        size   = (size.presence || config.default_page_size).to_i
        order  = order.to_s.downcase.to_sym

        if size < 1 || size > config.max_page_size
          raise InvalidParameterError.new(
            "page size must be a number between 1 and #{config.max_page_size} (got #{size})",
            parameter: "#{config.pagination_param_name}[size]",
          )
        end

        unless order in :asc | :desc
          raise InvalidParameterError.new('order is invalid', parameter: 'order')
        end

        unpaged = self
        paged   = keyset_paginator.call(unpaged, cursor:, size:, order:)

        # decorate relation with pagination helpers
        paged.extending(
          Page.new(
            unpaged:,
            cursor:,
            order:,
          ),
        )
      }
    end
  end
end

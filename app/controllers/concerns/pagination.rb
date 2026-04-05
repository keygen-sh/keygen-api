# frozen_string_literal: true

module Pagination
  DEFAULT_PAGE_ORDER = :desc
  DEFAULT_PAGE_SIZE  = 10

  extend ActiveSupport::Concern

  included do
    def render(*args, &)
      return super unless args in [Hash(jsonapi:) => options]

      resource = options.delete(:jsonapi)
      links    = resource.pagination_links if resource.respond_to?(:pagination_links)

      super(options.merge(jsonapi: resource, links:), &)
    end

    private

    def apply_pagination(scope)
      paged = Paginator.new(scope, request:).call

      # decorate records with pagination links for later use
      paged.records.extending(
        Page.new(paged:),
      )
    end
  end

  class Page < Module
    def initialize(paged:)
      super()

      define_method(:pagination_links) { paged.links }
    end
  end

  class Paginator
    attr_reader :request

    def initialize(scope, request:)
      @scope   = scope
      @request = request
    end

    def call
      params = Params.new(request.query_parameters)

      case pagination_type_for(params)
      when :keyset
        paginate_with_keyset(cursor: params.cursor, size: params.size, order: params.order)
      when :offset
        paginate_with_offset(number: params.number, size: params.size, order: params.order)
      else
        paginate_with_limit(limit: params.limit, order: params.order)
      end
    end

    private

    attr_reader :scope

    def pagination_type_for(params)
      if params.paginated?
        return :keyset if params.cursor?
        return :offset if params.offset?
      end

      :limit
    end

    def paginate_with_keyset(cursor:, size:, order:)
      records = scope.with_keyset_pagination(
        cursor:,
        size:,
        order:,
      )

      KeysetResult.new(records:, request:)
    end

    def paginate_with_offset(number:, size:, order:)
      records = scope.with_order(order)
                     .with_offset_pagination(number:, size:)

      OffsetResult.new(records:, request:)
    end

    def paginate_with_limit(limit:, order:)
      records = scope.with_order(order)
                     .with_limit(limit)

      LimitResult.new(records:, request:)
    end
  end

  class Params
    attr_reader :order, :limit, :number, :size, :cursor

    def initialize(query)
      @query = query
      @page  = @query.fetch(:page, {})

      unless @page in { number: Integer | String, size: Integer | String } |
                      { number: Integer | String } |
                      { cursor: String, size: Integer | String } |
                      { cursor: String } |
                      { **nil }
        raise Keygen::Error::InvalidParameterError.new(parameter: 'page'), 'page must be an object containing a cursor or number and optional size'
      end

      @order  = @query.fetch(:order, DEFAULT_PAGE_ORDER)
      @limit  = @query.fetch(:limit, DEFAULT_PAGE_SIZE).to_i
      @number = @page.fetch(:number, 0).to_i
      @size   = @page.fetch(:size, limit).to_i # use limit if set, default otherwise
      @cursor = @page.fetch(:cursor, nil)
    end

    def paginated? = query.key?(:page)
    def offset?    = page.key?(:number)
    def cursor?    = page.key?(:cursor)

    private

    attr_reader :query, :page
  end

  class AbstractResult
    attr_reader :records, :request

    def initialize(records:, request:)
      @records = records
      @request = request
    end

    def links = raise NotImplementedError

    private

    def build_link(**page)
      page = page.compact
      return nil if
        page.blank?

      params = request.query_parameters.except(:token, :auth)
                                       .merge(page: {
                                         size: records.limit_value,
                                         **page,
                                       })

      "#{request.path}?#{params.to_query}"
    end
  end

  class KeysetResult < AbstractResult
    def links
      {
        self: build_link(cursor: records.current_cursor.to_s), # retain empty cursor
        next: if records.has_more?
                build_link(cursor: records.next_cursor)
              else
                nil
              end,
      }
    end
  end

  class OffsetResult < AbstractResult
    def links
      count = records.total_count unless
        records.singleton_class < Kaminari::PaginatableWithoutCount

      if count
        {
          self: build_link(number: records.current_page),
          prev: build_link(number: records.prev_page),
          next: build_link(number: records.next_page),
          first: build_link(number: 1),
          last: build_link(number: records.total_pages),
          meta: { pages: records.total_pages, count: count },
        }
      else
        current_page = records.current_page
        prev_page    = current_page > 1 ? current_page - 1 : nil
        next_page    = records.length < records.limit_value ? nil : current_page + 1

        {
          self: build_link(number: current_page),
          prev: build_link(number: prev_page),
          next: build_link(number: next_page),
        }
      end
    end
  end

  class LimitResult < AbstractResult
    def links = {}
  end
end

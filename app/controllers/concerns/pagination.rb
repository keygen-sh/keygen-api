# frozen_string_literal: true

module Pagination
  DEFAULT_SORT_ORDER = 'desc'
  DEFAULT_PAGE_SIZE  = 10

  extend ActiveSupport::Concern

  included do
    # Overload render method to append pagination links to JSONAPI responses
    def render(args, ...)
      return super(args, ...) unless args.is_a?(Hash) && args.key?(:jsonapi)

      super(args.merge(links: pagination_links(jsonapi)), ...) unless performed?
    rescue => e # TODO: Let's not catch everything here
      Keygen.logger.exception(e)

      super(args, ...) unless performed? # Avoid double render
    end

    private

    def apply_pagination(scope)
      query = request.query_parameters

      scope = scope.with_order(query.fetch(:order, DEFAULT_SORT_ORDER)) if
        scope.model < Orderable

      if query.key?(:page)
        raise Keygen::Error::InvalidParameterError.new(parameter: 'page'), 'page must be an object' unless
          query[:page].is_a?(Hash)

        scope = scope.with_pagination(query.dig(:page, :number), query.dig(:page, :size)) if
          scope.model < Pageable
      else
        scope = scope.with_limit(query.fetch(:limit, DEFAULT_PAGE_SIZE)) if
          scope.model < Limitable
      end

      scope
    end
  end

  private

  def pagination_links(resource)
    return {} unless resource.respond_to?(:total_pages)

    {}.tap do |links|
      # This will raise if the paginated model is not countable (see pageable model concern)
      count = resource.total_count rescue nil

      if !count.nil?
        links[:self]  = pagination_link resource.current_page, resource.limit_value
        links[:prev]  = pagination_link resource.prev_page, resource.limit_value
        links[:next]  = pagination_link resource.next_page, resource.limit_value
        links[:first] = pagination_link 1, resource.limit_value
        links[:last]  = pagination_link resource.total_pages, resource.limit_value
        links[:meta]  = {
          pages: resource.total_pages,
          count: resource.total_count
        }
      else
        current_page = resource.current_page
        prev_page = current_page == 1 ? nil : current_page - 1
        next_page = resource.length < resource.limit_value ? nil : current_page + 1

        links[:self] = pagination_link current_page, resource.limit_value
        links[:prev] = pagination_link prev_page, resource.limit_value
        links[:next] = pagination_link next_page, resource.limit_value
      end
    end
  end

  def pagination_link(number, size)
    return if number.nil?

    "#{pagination_resource_path}?#{pagination_query_params(number, size)}"
  end

  def pagination_query_params(number, size)
    request.query_parameters.except(:token, :auth)
                            .merge(page: { number: number || 1, size: size })
                            .to_query
  end

  def pagination_resource_path
    request.path
  end
end

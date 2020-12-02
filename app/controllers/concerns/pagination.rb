# frozen_string_literal: true

module Pagination
  extend ActiveSupport::Concern

  # Overload render method to append pagination links to response
  included do
    def render(args)
      super args.merge links: pagination_links(args[:jsonapi]) unless performed?
    rescue => e # TODO: Let's not catch everything here
      Rails.logger.error e

      super args unless performed? # Avoid double render
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
    request.query_parameters.merge(page: { number: number || 1, size: size }).to_query
  end

  def pagination_resource_path
    request.path
  end
end

module Pagination
  extend ActiveSupport::Concern

  # Overload render method to append pagination links to response
  included do
    def render(args)
      super args.merge links: pagination_links(args[:jsonapi]) # unless performed?
    rescue => e # TODO: Let's not catch everything here
      Raygun.track_exception e, request.env.to_h.slice(
        "REQUEST_METHOD",
        "PATH_INFO",
        "QUERY_STRING",
        "CONTENT_LENGTH",
        "CONTENT_TYPE",
        "HTTP_ACCEPT"
      ) rescue nil

      super args unless performed? # Avoid double render
    end
  end

  private

  def pagination_links(resource)
    return {} unless resource.respond_to?(:total_pages) && resource.total_pages > 1

    {}.tap do |page|
      page[:self] = pagination_link resource.current_page, resource.limit_value

      if resource.current_page > 1
        page[:first] = pagination_link 1, resource.limit_value
        page[:prev]  = pagination_link resource.prev_page, resource.limit_value
      end

      if resource.current_page < resource.total_pages
        page[:next] = pagination_link resource.next_page, resource.limit_value
        page[:last] = pagination_link resource.total_pages, resource.limit_value
      end
    end
  end

  def pagination_link(number, size)
    "#{pagination_resource_path}?#{pagination_query_params(number, size)}"
  end

  def pagination_query_params(number, size)
    request.query_parameters.merge(page: { number: number, size: size }).to_query
  end

  def pagination_resource_path
    request.path
  end
end

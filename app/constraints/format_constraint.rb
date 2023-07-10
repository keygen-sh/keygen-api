# frozen_string_literal: true

class FormatConstraint
  def initialize(format:) = @formats = Array(format)

  # Assert that both the Accept header and requested :format matches
  # our allowed format. For example, if a route requires the :jsonapi
  # format, then both an Accept: text/html header as well as an .html
  # path parameter will fail, even if there's a default :format.
  #
  # This differs from Rails' default constraint behavior for :format,
  # where it will not look at the request headers if there is a
  # default :format supplied on the route.
  def matches?(request)
    @formats.any? { request.format == _1 } &&
      @formats.any? { |format|
        request.accepts.none? || request.accepts.any? { _1 == '*/*' || _1 == format }
      }
  end
end
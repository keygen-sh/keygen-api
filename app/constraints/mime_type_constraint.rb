# frozen_string_literal: true

class MimeTypeConstraint
  def initialize(*mimes, raise_on_no_match: false, except: [])
    @mimes             = Array(mimes.flatten)
    @raise_on_no_match = raise_on_no_match
    @except            = except
  end

  # Assert that both the Accept header and requested path :format matches
  # our allowed mimes. For example, if a route requires the :jsonapi
  # format, then both an Accept: text/html header as well as an .html
  # path parameter will fail, even if there's a default :format.
  #
  # This differs from Rails' default constraint behavior for :format,
  # where it will not look at the request headers if there is a
  # default :format supplied on the route.
  def matches?(request)
    return true if
      except.any? { |params|
        params <= request.params.slice(:format, :controller, :action)
                                .symbolize_keys
      }

    unless ok = path_format_matches?(request) && accept_header_matches?(request)
      raise Mime::Type::InvalidMimeType if
        raise_on_no_match?
    end

    ok
  end

  private

  attr_reader :mimes,
              :except

  def raise_on_no_match? = !!@raise_on_no_match

  def path_format_matches?(request)
    mimes.any? { request.format == _1 }
  end

  def accept_header_matches?(request)
    mimes.any? { |mime|
      request.accepts.none? || request.accepts.any? { _1 == '*/*' || _1 == mime }
    }
  end
end
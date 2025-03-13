module Keygen
  module UrlFor
    extend self

    def url_for(base_url, path: nil, query: nil, anchor: nil, trailing_slash: false)
      url = URI.parse(base_url)

      unless path.nil?
        url.path  = url.path.delete_suffix('/')
        url.path += '/' unless path.to_s.starts_with?('/')
        url.path += path.to_s
        url.path += '/' if trailing_slash
      end

      url.query    = query.compact.to_query unless query.nil?
      url.fragment = anchor.to_s unless anchor.nil?

      url.to_s
    end
  end
end

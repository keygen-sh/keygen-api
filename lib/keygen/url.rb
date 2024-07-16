# frozen_string_literal: true

module Keygen
  module URL
    PORTAL_BASE_URL = 'https://portal.keygen.sh'.freeze
    DOCS_BASE_URL   = 'https://keygen.sh/docs/api'.freeze

    class << self
      def portal_url(record_or_path = nil, **) = case record_or_path
                                                 in Account => account
                                                   url_for(PORTAL_BASE_URL, path: account.slug, **)
                                                 in String | Symbol => path
                                                   url_for(PORTAL_BASE_URL, path:, **)
                                                 else
                                                   url_for(PORTAL_BASE_URL, **)
                                                 end

      def docs_url(topic = nil, **) = url_for(DOCS_BASE_URL, trailing_slash: true, path: topic.presence, **)

      private

      def url_for(base_url, path: nil, query: nil, anchor: nil, trailing_slash: false)
        url = URI.parse(base_url)

        unless path.nil?
          url.path += '/' unless path.to_s.starts_with?('/')
          url.path += path.to_s
          url.path += '/' if trailing_slash
        end

        url.query    = query.to_query unless query.nil?
        url.fragment = anchor.to_s unless anchor.nil?

        url.to_s
      end
    end
  end
end

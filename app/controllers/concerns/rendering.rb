# frozen_string_literal: true

module Rendering
  module Base
    extend ActiveSupport::Concern

    included do
      include ActionController::MimeResponds

      # overload render method to automatically set content type
      def render(options, ...)
        mime_type, * = Mime::Type.parse(response.content_type.to_s) rescue nil

        # skip if we've already set content type
        unless mime_type.nil?
          return super
        end

        case options
        in jsonapi: _
          response.content_type = Mime::Type.lookup_by_extension(:jsonapi)
        in json: _
          response.content_type = Mime::Type.lookup_by_extension(:json)
        in body: _
          response.content_type = Mime::Type.lookup_by_extension(:binary)
        in html: _
          response.content_type = Mime::Type.lookup_by_extension(:html)
        in gz: _
          response.content_type = Mime::Type.lookup_by_extension(:gzip)
        else
          # leave as-is
        end

        super
      end
    end
  end

  module JSON
    extend ActiveSupport::Concern

    included do
      include Base
    end
  end

  module HTML
    extend ActiveSupport::Concern

    # NOTE(ezekg) this concern adds back support for rendering views since
    #             we're using ActionController::API as our base class
    included do
      include ActionController::Rendering
      include ActionController::Helpers
      include ActionView::Rendering
      include ActionView::Layouts
      include Base

      # FIXME(ezekg) why isn't this automatically loaded?
      self.helpers_path = ActionController::Helpers.helpers_path
      helper :all
    end
  end
end

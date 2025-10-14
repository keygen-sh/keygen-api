# frozen_string_literal: true

module Rendering
  module Base
    extend ActiveSupport::Concern

    included do
      include ActionController::MimeResponds

      # overload render method to more intelligently set the content-type header, regardless
      # of the current route default format (which is a great default but can fall short
      # when a user accepts a content-type that differs from the route format)
      def render(*args, &)
        return super unless response.content_type.nil?
        return super unless args in [Hash => options]

        case options
        in { jsonapi: _ } | { json: _ }
          # NOTE(ezekg) we're using request.accepts instead of request.formats because #formats
          #             prioritizes route default format over accept header, which isn't what
          #             we want (i.e. we *always* want to respond in the requested format)
          case request.accepts
          in [*, Mime::Type[:jsonapi], *] unless (request.accepts.index(Mime[:jsonapi]) <=> request.accepts.index(Mime[:json])) == 1 # respect priority
            response.content_type = Mime[:jsonapi]
          in [*, Mime::Type[:json], *] unless (request.accepts.index(Mime[:jsonapi]) <=> request.accepts.index(Mime[:json])) == -1
            response.content_type = Mime[:json]
          in [*] if request.format == :json # json is largely synonymous with jsonapi unless the route format is json
            response.content_type = Mime[:json]
          else
            response.content_type = Mime[:jsonapi]
          end
        in body: _
          response.content_type = Mime[:binary]
        in html: _
          response.content_type = Mime[:html]
        in gz: _
          response.content_type = Mime[:gzip]
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

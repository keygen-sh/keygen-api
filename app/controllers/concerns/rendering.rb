# frozen_string_literal: true

module Rendering
  module Base
    extend ActiveSupport::Concern

    included do
      # Overload render method to automatically set content type
      def render(args, ...)
        case args
        in jsonapi:
          response.content_type = Mime::Type.lookup_by_extension(:jsonapi)
        in json:
          response.content_type = Mime::Type.lookup_by_extension(:json)
        in body:
          response.content_type = Mime::Type.lookup_by_extension(:binary)
        in html:
          response.content_type = Mime::Type.lookup_by_extension(:html)
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

    # NOTE(ezekg) This concern adds back support for rendering views since
    #             we're using ActionController::API as our base class.
    included do
      include ActionController::Rendering
      include ActionController::Helpers
      include ActionView::Rendering
      include ActionView::Layouts
      include Base

      # FIXME(ezekg) Why isn't this automatically loaded?
      self.helpers_path = ActionController::Helpers.helpers_path
      helper :all
    end
  end
end

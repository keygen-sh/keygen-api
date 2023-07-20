# frozen_string_literal: true

module Rendering
  module Refinements
    # Refine #responds_to's format.any to accept an :except keyword, for
    # defining a responder for any format except the provided, which
    # should be handled explicitly (otherwise will be rejected).
    refine ActionController::MimeResponds::Collector do
      def any(*mimes, except: nil, &block)
        case
        when except.present?
          excluded = Array(except).map { Mime[_1] }
          rest     = Mime::SET.excluding(excluded)

          rest.each { send(_1.to_sym, &block) }
        when mimes.any?
          mimes.each { send(_1, &block) }
        else
          custom(Mime::ALL, &block)
        end
      end
    end
  end

  module Base
    extend ActiveSupport::Concern

    included do
      include ActionController::MimeResponds

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

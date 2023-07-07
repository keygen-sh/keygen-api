# frozen_string_literal: true

module Rendering
  extend ActiveSupport::Concern

  # NOTE(ezekg) This concern adds back support for rendering views since
  #             we're using ActionController::API as our base class.
  included do
    include ActionController::Rendering
    include ActionController::Helpers
    include ActionView::Rendering
    include ActionView::Layouts

    self.helpers_path = ActionController::Helpers.helpers_path
    helper :all

    before_action :set_content_type

    # Redefine rendering methods to not respond with JSON. We don't really
    # need to provide detailed errors for e.g. PyPI.
    Rack::Utils::SYMBOL_TO_STATUS_CODE.each do |status, code|
      if Rack::Utils::STATUS_WITH_NO_ENTITY_BODY.include?(code)
        define_method :"render_#{status}" do |*, **|
          skip_verify_authorized!

          head status
        end
      else
        define_method :"render_#{status}" do |*, **|
          skip_verify_authorized!

          render html: Rack::Utils::HTTP_STATUS_CODES[code],
                 status:
        end
      end
    end

    private

    def set_content_type = response.headers['Content-Type'] = mime_type

    # TODO(ezekg) Make this configurable so that e.g. our Sparkle engine
    #             can use an :xml content type.
    def mime_type = Mime::Type.lookup_by_extension(:html).to_s
  end
end
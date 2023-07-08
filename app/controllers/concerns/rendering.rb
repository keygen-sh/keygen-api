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

    # FIXME(ezekg) Why isn't this automatically loaded?
    self.helpers_path = ActionController::Helpers.helpers_path
    helper :all
  end
end
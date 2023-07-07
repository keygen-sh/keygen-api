# frozen_string_literal: true

# FIXME(ezekg) Not entirely sure why this is needed when we *should*
#              already have access to ActionView::RoutingUrlFor.
#              Gotta be something to do with ActionController::API.
module UrlHelper
  include ActionView::RoutingUrlFor
  include Rails.application.routes.url_helpers

  def _routes = Rails.application.routes

  # TODO(ezekg) Make this configurable so that we can use the helper
  #             elsewhere, e.g. in serializers.
  def _generate_paths_by_default = false
end
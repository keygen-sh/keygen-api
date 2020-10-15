# frozen_string_literal: true

module Api::V1
  class ProfilesController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!

    # GET /profile
    def show
      authorize current_bearer

      render jsonapi: current_bearer, meta: { tokenId: current_token&.id }
    end

    # GET /me
    def me
      authorize current_bearer

      # FIXME(ezekg) Move JSONAPI rendering into a service so that it's easier to
      #              switch to Netflix's JSONAPI lib, and also less verbose.
      renderer = JSONAPI::Serializable::Renderer.new
      rendered_bearer = renderer.render(current_bearer, {
        expose: { url_helpers: Rails.application.routes.url_helpers },
        class: {
          Account: SerializableAccount,
          Product: SerializableProduct,
          License: SerializableLicense,
          User: SerializableUser,
          Error: SerializableError,
        }
      })

      rendered_token = renderer.render(current_token, {
        expose: { url_helpers: Rails.application.routes.url_helpers },
        class: {
          Account: SerializableAccount,
          Token: SerializableToken,
          Product: SerializableProduct,
          License: SerializableLicense,
          User: SerializableUser,
          Error: SerializableError,
        }
      })

      rendered_bearer.tap do |data|
        token_payload = rendered_token[:data]

        data[:included] = [token_payload]
      end

      render json: rendered_bearer
    end
  end
end

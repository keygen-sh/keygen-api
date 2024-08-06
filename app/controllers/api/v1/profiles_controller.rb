# frozen_string_literal: true

module Api::V1
  class ProfilesController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :authenticate!

    def show
      authorize! current_bearer

      render jsonapi: current_bearer, meta: { tokenId: current_token&.id }
    end

    def me
      authorize! current_bearer

      # FIXME(ezekg) Move JSONAPI rendering into a service so that it's easier to
      #              switch to Netflix's JSONAPI lib, and also less verbose.
      renderer        = Keygen::JSONAPI::Renderer.new(account: current_account, bearer: current_bearer, token: current_token)
      rendered_bearer = renderer.render(current_bearer)

      if current_token.present?
        rendered_token = renderer.render(current_token)

        rendered_bearer.tap do |data|
          token_payload = rendered_token[:data]

          data[:included] = [token_payload]
        end
      end

      render json: rendered_bearer
    end
  end
end

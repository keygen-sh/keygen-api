# frozen_string_literal: true

module Api::V1::Licenses::Actions
  class CheckoutsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_license

    def checkout
      authorize license

      kwargs   = checkout_query.to_h.symbolize_keys.slice(:include, :ttl)
      flatfile = GenerateFlatfileService.call(
        account: current_account,
        resource: license,
        **kwargs,
      )

      headers['Content-Type'] = 'text/plain'

      render plain: flatfile
    rescue GenerateFlatfileService::InvalidIncludedResourceError => e
      render_bad_request detail: e.message, source: { parameter: :include }
    rescue GenerateFlatfileService::InvalidTTLError => e
      render_bad_request detail: e.message, source: { parameter: :ttl }
    end

    private

    attr_reader :license

    def set_license
      @license = FindByAliasService.call(scope: current_account.licenses, identifier: params[:id], aliases: :key)
    end

    typed_query do
      on :checkout do
        query :include, type: :string, optional: true
        query :ttl, type: :integer, coerce: true, optional: true
      end
    end
  end
end

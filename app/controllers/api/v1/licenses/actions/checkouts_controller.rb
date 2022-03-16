# frozen_string_literal: true

module Api::V1::Licenses::Actions
  class CheckoutsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_license

    def checkout
      authorize license

      kwargs = checkout_query.to_h.symbolize_keys.slice(:include, :encrypt, :ttl)
      file   = LicenseCheckoutService.call(
        account: current_account,
        license: license,
        **kwargs,
      )

      BroadcastEventService.call(
        event: 'license.checkout',
        account: current_account,
        resource: license,
      )

      response.headers['Content-Disposition'] = %(attachment; filename="license+#{license.id}.lic")
      response.headers['Content-Type']        = 'text/plain'

      render body: file
    end

    private

    attr_reader :license

    def set_license
      scoped_licenses = policy_scope(current_account.licenses)

      @license = FindByAliasService.call(scope: scoped_licenses, identifier: params[:id], aliases: :key)

      Current.resource = license
    end

    typed_query do
      on :checkout do
        if current_bearer&.has_role?(:admin, :developer, :sales_agent, :support_agent, :product)
          param :include, type: :string, optional: true, transform: -> k, v { [k, v.split(',')] }
          param :encrypt, type: :boolean, optional: true
          param :ttl, type: :integer, optional: true
        end
      end
    end
  end
end

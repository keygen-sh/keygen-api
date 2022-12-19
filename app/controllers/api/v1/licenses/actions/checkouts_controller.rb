# frozen_string_literal: true

module Api::V1::Licenses::Actions
  class CheckoutsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_license

    authorize :license

    typed_query {
      param :include, type: :array, coerce: true, optional: true
      param :encrypt, type: :boolean, coerce: true, optional: true
      param :ttl, type: :integer, coerce: true, allow_nil: true, optional: true
    }
    def show
      kwargs = checkout_query.slice(
        :include,
        :encrypt,
        :ttl,
      )

      license_file = checkout_license_file(**kwargs)

      response.headers['Content-Disposition'] = %(attachment; filename="#{license.id}.lic")
      response.headers['Content-Type']        = 'application/octet-stream'

      render body: license_file.certificate
    rescue LicenseCheckoutService::InvalidIncludeError => e
      render_bad_request detail: e.message, code: :CHECKOUT_INCLUDE_INVALID, source: { parameter: :include }
    rescue LicenseCheckoutService::InvalidTTLError => e
      render_bad_request detail: e.message, code: :CHECKOUT_TTL_INVALID, source: { parameter: :ttl }
    rescue LicenseCheckoutService::InvalidAlgorithmError => e
      render_unprocessable_entity detail: e.message
    end

    typed_params {
      format :jsonapi

      param :meta, type: :hash, optional: true do
        param :include, type: :array, optional: true
        param :encrypt, type: :boolean, optional: true
        param :ttl, type: :integer, coerce: true, allow_nil: true, optional: true
      end
    }
    typed_query {
      param :include, type: :array, coerce: true, optional: true
      param :encrypt, type: :boolean, coerce: true, optional: true
      param :ttl, type: :integer, coerce: true, allow_nil: true, optional: true
    }
    def create
      kwargs = checkout_query.merge(checkout_meta)
                             .slice(
                               :include,
                               :encrypt,
                               :ttl,
                              )

      license_file = checkout_license_file(**kwargs)

      render jsonapi: license_file
    rescue LicenseCheckoutService::InvalidIncludeError => e
      render_bad_request detail: e.message, code: :CHECKOUT_INCLUDE_INVALID, source: { parameter: :include }
    rescue LicenseCheckoutService::InvalidTTLError => e
      render_bad_request detail: e.message, code: :CHECKOUT_TTL_INVALID, source: { parameter: :ttl }
    rescue LicenseCheckoutService::InvalidAlgorithmError => e
      render_unprocessable_entity detail: e.message
    end

    private

    attr_reader :license

    def set_license
      scoped_licenses = authorized_scope(current_account.licenses)

      @license = FindByAliasService.call(scope: scoped_licenses, identifier: params[:id], aliases: :key)

      Current.resource = license
    end

    def checkout_license_file(**kwargs)
      authorize! license,
        to: :check_out?

      license_file = LicenseCheckoutService.call(
        account: current_account,
        license:,
        **kwargs,
      )
      authorize! license_file,
        to: :show?

      license_file.validate!
      license.touch(:last_check_out_at)

      BroadcastEventService.call(
        event: 'license.checked-out',
        account: current_account,
        resource: license,
      )

      license_file
    end
  end
end

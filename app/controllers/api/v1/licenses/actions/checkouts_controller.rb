# frozen_string_literal: true

module Api::V1::Licenses::Actions
  class CheckoutsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_license

    authorize :license

    typed_query {
      param :encrypt, type: :boolean, coerce: true, optional: true
      param :algorithm, type: :string, allow_blank: true, optional: true
      param :ttl, type: :integer, coerce: true, allow_nil: true, optional: true
      param :include, type: :array, coerce: true, allow_blank: true, optional: true, transform: -> key, includes {
        # FIXME(ezekg) For backwards compatibility. Replace user include with
        #              owner when present.
        includes.push('owner') if includes.delete('user')

        [key, includes]
      }
    }
    def show
      kwargs = checkout_query.slice(
        :algorithm,
        :include,
        :encrypt,
        :ttl,
      )

      license_file = checkout_license_file(**kwargs)

      response.headers['Content-Disposition'] = %(attachment; filename="#{license.id}.lic")
      response.headers['Content-Type']        = 'application/octet-stream'

      render body: license_file.certificate
    rescue LicenseCheckoutService::InvalidAlgorithmError => e
      render_bad_request detail: e.message, code: :CHECKOUT_ALGORITHM_INVALID, source: { parameter: :algorithm }
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
        param :encrypt, type: :boolean, optional: true
        param :algorithm, type: :string, allow_blank: true, allow_nil: true, optional: true
        param :ttl, type: :integer, coerce: true, allow_nil: true, optional: true
        param :include, type: :array, allow_blank: true, optional: true, transform: -> key, includes {
          includes.push('owner') if includes.delete('user')

          [key, includes]
        }
      end
    }
    typed_query {
      param :encrypt, type: :boolean, coerce: true, optional: true
      param :algorithm, type: :string, allow_blank: true, optional: true
      param :ttl, type: :integer, coerce: true, allow_nil: true, optional: true
      param :include, type: :array, coerce: true, allow_blank: true, optional: true, transform: -> key, includes {
        includes.push('owner') if includes.delete('user')

        [key, includes]
      }
    }
    def create
      kwargs = checkout_query.merge(checkout_meta)
                             .slice(
                               :algorithm,
                               :include,
                               :encrypt,
                               :ttl,
                             )

      license_file = checkout_license_file(**kwargs)

      render jsonapi: license_file
    rescue LicenseCheckoutService::InvalidAlgorithmError => e
      render_bad_request detail: e.message, code: :CHECKOUT_ALGORITHM_INVALID, source: { parameter: :algorithm }
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
      scoped_licenses = authorized_scope(current_account.licenses).lazy_preload(
        users: :role,
      )

      @license = FindByAliasService.call(scoped_licenses, id: params[:id], aliases: :key)

      Current.resource = license
    end

    def checkout_license_file(**kwargs)
      authorize! license,
        to: :check_out?

      license_file = LicenseCheckoutService.call(
        api_version: current_api_version,
        environment: current_environment,
        account: current_account,
        license:,
        **kwargs,
      )
      authorize! license_file,
        to: :show?

      license_file.validate!
      license.touch_async!(:last_check_out_at,
        time: Time.current,
      )

      BroadcastEventService.call(
        event: 'license.checked-out',
        account: current_account,
        resource: license,
      )

      license_file
    end
  end
end

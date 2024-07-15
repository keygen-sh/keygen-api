# frozen_string_literal: true

module Api::V1::Licenses::Actions
  class ValidationsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate!, except: %i[validate_by_key]
    before_action :authenticate, only: %i[validate_by_key]
    before_action :set_license, only: %i[quick_validate_by_id validate_by_id]

    def quick_validate_by_id
      authorize! license,
        to: :validate?

      # FIXME(ezekg) Skipping :touch on origin is not a good idea, since
      #              the origin header can be set by anybody.
      valid, detail, code = LicenseValidationService.call(license: license, scope: false, skip_touch: request.headers['origin'] == 'https://app.keygen.sh')
      meta = {
        ts: Time.current, # Included so customer has a signed ts to utilize elsewhere
        valid:,
        detail:,
        code:,
      }

      Keygen.logger.info "[license.quick-validate] account_id=#{current_account.id} license_id=#{license&.id} validation_valid=#{valid} validation_detail=#{detail} validation_code=#{code}"

      Current.resource = license if
        license.present?

      render jsonapi: license, meta: meta
    end

    typed_params {
      format :jsonapi

      param :meta, type: :hash, optional: true do
        param :nonce, type: :integer, optional: true
        param :scope, type: :hash, optional: true do
          param :product, type: :string, optional: true
          param :policy, type: :string, optional: true
          param :user, type: :string, allow_nil: true, optional: true
          param :machine, type: :string, optional: true
          param :fingerprint, type: :string, optional: true
          param :fingerprints, type: :array, optional: true do
            items type: :string
          end
          param :components, type: :array, optional: true do
            items type: :string
          end
          param :entitlements, type: :array, optional: true do
            items type: :string
          end
          param :checksum, type: :string, optional: true
          param :version, type: :string, optional: true

          Keygen.ee do |license|
            next unless
              license.entitled?(:environments)

            param :environment, type: :string, allow_nil: true, optional: true
          end
        end
      end
    }
    def validate_by_id
      authorize! license,
        to: :validate?

      valid, detail, code = LicenseValidationService.call(license: license, scope: validation_meta[:scope])
      meta = {
        ts: Time.current,
        valid:,
        detail:,
        code:,
      }

      if nonce = validation_meta[:nonce]
        meta[:nonce] = nonce
      end

      if scope = validation_meta[:scope]
        meta[:scope] = scope
      end

      Keygen.logger.info "[license.validate] account_id=#{current_account.id} license_id=#{license&.id} validation_valid=#{valid} validation_detail=#{detail} validation_code=#{code} validation_scope=#{scope} validation_nonce=#{nonce}"

      if license.present?
        Current.resource = license

        BroadcastEventService.call(
          event: valid ? "license.validation.succeeded" : "license.validation.failed",
          account: current_account,
          resource: license,
          meta: meta
        )
      end

      render jsonapi: license, meta: meta
    end

    typed_params {
      format :jsonapi

      param :meta, type: :hash do
        param :key, type: :string, allow_blank: false
        param :legacy_encrypted, type: :boolean, optional: true
        param :encrypted, type: :boolean, optional: true
        param :nonce, type: :integer, optional: true
        param :scope, type: :hash, optional: true do
          param :product, type: :string, optional: true
          param :policy, type: :string, optional: true
          param :user, type: :string, allow_nil: true, optional: true
          param :machine, type: :string, optional: true
          param :fingerprint, type: :string, optional: true
          param :fingerprints, type: :array, optional: true do
            items type: :string
          end
          param :components, type: :array, optional: true do
            items type: :string
          end
          param :entitlements, type: :array, optional: true do
            items type: :string
          end
          param :checksum, type: :string, optional: true
          param :version, type: :string, optional: true

          Keygen.ee do |license|
            next unless
              license.entitled?(:environments)

            param :environment, type: :string, allow_nil: true, optional: true
          end
        end
      end
    }
    def validate_by_key
      @license = LicenseKeyLookupService.call(
        environment: current_environment,
        account: current_account,
        key: validation_meta[:key],
        # Since we've added new encryption schemes, we only want to alter
        # the lookup for legacy encrypted licenses.
        legacy_encrypted: validation_meta[:legacy_encrypted] == true ||
                          validation_meta[:encrypted] == true
      )

      authorize! license,
        with: LicensePolicy,
        to: :validate_key?

      valid, detail, code = LicenseValidationService.call(license: license, scope: validation_meta[:scope])
      meta = {
        ts: Time.current,
        valid:,
        detail:,
        code:,
      }

      if nonce = validation_meta[:nonce]
        meta[:nonce] = nonce
      end

      if scope = validation_meta[:scope]
        meta[:scope] = scope
      end

      Keygen.logger.info "[license.validate-key] account_id=#{current_account.id} license_id=#{license&.id} validation_valid=#{valid} validation_detail=#{detail} validation_code=#{code} validation_scope=#{scope} validation_nonce=#{nonce}"

      if license.present?
        Current.resource = license

        BroadcastEventService.call(
          event: valid ? "license.validation.succeeded" : "license.validation.failed",
          account: current_account,
          resource: license,
          meta: meta
        )
      end

      render jsonapi: license, meta: meta
    end

    private

    attr_reader :license

    def set_license
      scoped_licenses = authorized_scope(current_account.licenses)

      @license = FindByAliasService.call(scoped_licenses, id: params[:id], aliases: :key)

      Current.resource = license
    end
  end
end

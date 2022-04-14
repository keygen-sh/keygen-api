# frozen_string_literal: true

module Api::V1::Licenses::Actions
  class ValidationsController < Api::V1::BaseController
    ALLOWED_INCLUDES = %w[
      entitlements
      product
      policy
      group
      user
    ]

    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!, except: %i[validate_by_key]
    before_action :authenticate_with_token, only: %i[validate_by_key]
    before_action :set_license, only: %i[quick_validate_by_id validate_by_id]

    # GET /licenses/1/validate
    def quick_validate_by_id
      authorize license

      valid, detail, constant = LicenseValidationService.call(license:, scope: false, skip_touch: request.headers['origin'] == 'https://app.keygen.sh')
      meta = {
        ts: Time.current, # Included so customer has a signed ts to utilize elsewhere
        constant:,
        detail:,
        valid:,
      }

      Keygen.logger.info "[license.quick-validate] account_id=#{current_account.id} license_id=#{license&.id} validation_valid=#{valid} validation_detail=#{detail} validation_code=#{constant} validation_includes=#{nil}"

      render jsonapi: license, meta:
    end

    # POST /licenses/1/validate
    def validate_by_id
      authorize license

      valid, detail, constant = LicenseValidationService.call(license:, scope: validation_params.dig(:meta, :scope))
      include = Array(validation_query[:include] || validation_params[:include]) & ALLOWED_INCLUDES
      meta = {
        ts: Time.current,
        constant:,
        detail:,
        valid:,
      }

      if nonce = validation_params.dig(:meta, :nonce)
        meta[:nonce] = nonce
      end

      if scope = validation_params.dig(:meta, :scope)
        meta[:scope] = scope
      end

      Keygen.logger.info "[license.validate] account_id=#{current_account.id} license_id=#{license&.id} validation_valid=#{valid} validation_detail=#{detail} validation_code=#{constant} validation_scope=#{scope} validation_nonce=#{nonce} validation_includes=#{include}"

      BroadcastEventService.call(
        event: valid ? 'license.validation.succeeded' : 'license.validation.failed',
        account: current_account,
        resource: license,
        meta:,
      )

      render jsonapi: license, meta:, include:
    end

    # POST /licenses/validate-key
    def validate_by_key
      @license = LicenseKeyLookupService.call(
        account: current_account,
        key: validation_params.dig(:meta, :key),
        # NOTE(ezekg) Since we've added new encryption schemes, we only want to alter
        #             the lookup for legacy encrypted licenses.
        legacy_encrypted: validation_params.dig(:meta, :legacy_encrypted) == true ||
                          validation_params.dig(:meta, :encrypted) == true
      )

      # We can skip authorization when the license doesn't exist
      if license.present?
        authorize license
      else
        skip_authorization
      end

      valid, detail, constant = LicenseValidationService.call(license:, scope: validation_params.dig(:meta, :scope))
      include = Array(validation_query[:include] || validation_params[:include]) & ALLOWED_INCLUDES
      meta = {
        ts: Time.current,
        constant:,
        detail:,
        valid:,
      }

      if nonce = validation_params.dig(:meta, :nonce)
        meta[:nonce] = nonce
      end

      if scope = validation_params.dig(:meta, :scope)
        meta[:scope] = scope
      end

      Keygen.logger.info "[license.validate-key] account_id=#{current_account.id} license_id=#{license&.id} validation_valid=#{valid} validation_detail=#{detail} validation_code=#{constant} validation_scope=#{scope} validation_nonce=#{nonce} validation_includes=#{include}"

      if license.present?
        Current.resource = license

        BroadcastEventService.call(
          event: valid ? 'license.validation.succeeded' : 'license.validation.failed',
          account: current_account,
          resource: license,
          meta:,
        )
      end

      render jsonapi: license, meta:, include:
    end

    private

    attr_reader :license

    def set_license
      @license = FindByAliasService.call(scope: current_account.licenses, identifier: params[:id], aliases: :key)

      Current.resource = license
    end

    typed_parameters do
      options strict: true

      on :validate_by_id do
        param :meta, type: :hash, optional: true do
          param :include, type: :array, optional: true
          param :nonce, type: :integer, optional: true
          param :scope, type: :hash, optional: true do
            param :product, type: :string, optional: true
            param :policy, type: :string, optional: true
            param :machine, type: :string, optional: true
            param :fingerprint, type: :string, optional: true
            param :fingerprints, type: :array, optional: true do
              items type: :string
            end
            param :entitlements, type: :array, optional: true do
              items type: :string
            end
            param :user, type: :string, optional: true
          end
        end
      end

      on :validate_by_key do
        param :meta, type: :hash do
          param :include, type: :array, optional: true
          param :key, type: :string, allow_blank: false
          param :legacy_encrypted, type: :boolean, optional: true
          param :encrypted, type: :boolean, optional: true
          param :nonce, type: :integer, optional: true
          param :scope, type: :hash, optional: true do
            param :product, type: :string, optional: true
            param :policy, type: :string, optional: true
            param :machine, type: :string, optional: true
            param :fingerprint, type: :string, optional: true
            param :fingerprints, type: :array, optional: true do
              items type: :string
            end
            param :entitlements, type: :array, optional: true do
              items type: :string
            end
            param :user, type: :string, optional: true
          end
        end
      end
    end

    typed_query do
      on :validate_by_id do
        param :include, type: :array, coerce: true, optional: true
      end

      on :validate_by_key do
        param :include, type: :array, coerce: true, optional: true
      end
    end
  end
end

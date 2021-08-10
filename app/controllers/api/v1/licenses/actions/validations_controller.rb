# frozen_string_literal: true

module Api::V1::Licenses::Actions
  class ValidationsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!, except: %i[validate_by_key]
    before_action :authenticate_with_token, only: %i[validate_by_key]
    before_action :set_license, only: %i[quick_validate_by_id validate_by_id]

    # GET /licenses/1/validate
    def quick_validate_by_id
      authorize @license

      valid, detail, constant = LicenseValidationService.call(license: @license, scope: false)
      meta = {
        ts: Time.current, # Included so customer has a signed ts to utilize elsewhere
        valid: valid,
        detail: detail,
        constant: constant,
      }

      Keygen.logger.info "[license.quick-validate] account_id=#{current_account.id} license_id=#{@license&.id} validation_valid=#{valid} validation_detail=#{detail} validation_code=#{constant}"

      if @license.present?
        Keygen::Store::Request.store[:current_resource] = @license

        @license.touch(:last_validated_at) unless
          # Only touch if it's different. Large spikes in concurrent validation
          # requests needlessly update this, causing slow queries due to locks.
          @license.last_validated_at.to_i == Time.current.to_i ||
          # Skip quick validations for dashboard since that's what we're using
          # to check license validity.
          request.headers['origin'] == 'https://app.keygen.sh'

        BroadcastEventService.call(
          event: valid ? "license.validation.succeeded" : "license.validation.failed",
          account: current_account,
          resource: @license,
          meta: meta
        )
      end

      render jsonapi: @license, meta: meta
    end

    # POST /licenses/1/validate
    def validate_by_id
      authorize @license

      valid, detail, constant = LicenseValidationService.call(license: @license, scope: validation_params.dig(:meta, :scope))
      meta = {
        ts: Time.current,
        valid: valid,
        detail: detail,
        constant: constant,
      }

      if nonce = validation_params.dig(:meta, :nonce)
        meta[:nonce] = nonce
      end

      if scope = validation_params.dig(:meta, :scope)
        meta[:scope] = scope
      end

      Keygen.logger.info "[license.validate] account_id=#{current_account.id} license_id=#{@license&.id} validation_valid=#{valid} validation_detail=#{detail} validation_code=#{constant} validation_scope=#{scope} validation_nonce=#{nonce}"

      if @license.present?
        Keygen::Store::Request.store[:current_resource] = @license

        @license.touch(:last_validated_at) unless
          # Only touch if it's different. Large spikes in concurrent validation
          # requests needlessly update this, causing slow queries due to locks.
          @license.last_validated_at.to_i == Time.current.to_i

        BroadcastEventService.call(
          event: valid ? "license.validation.succeeded" : "license.validation.failed",
          account: current_account,
          resource: @license,
          meta: meta
        )
      end

      render jsonapi: @license, meta: meta
    end

    # POST /licenses/validate-key
    def validate_by_key
      skip_authorization

      @license = LicenseKeyLookupService.call(
        account: current_account,
        key: validation_params[:meta][:key],
        # Since we've added new encryption schemes, we only want to alter
        # the lookup for legacy encrypted licenses.
        legacy_encrypted: validation_params[:meta][:legacy_encrypted] == true ||
                          validation_params[:meta][:encrypted] == true
      )

      valid, detail, constant = LicenseValidationService.call(license: @license, scope: validation_params[:meta][:scope])
      meta = {
        ts: Time.current,
        valid: valid,
        detail: detail,
        constant: constant,
      }

      if nonce = validation_params[:meta][:nonce]
        meta[:nonce] = nonce
      end

      if scope = validation_params[:meta][:scope]
        meta[:scope] = scope
      end

      Keygen.logger.info "[license.validate-key] account_id=#{current_account.id} license_id=#{@license&.id} validation_valid=#{valid} validation_detail=#{detail} validation_code=#{constant} validation_scope=#{scope} validation_nonce=#{nonce}"

      if @license.present?
        Keygen::Store::Request.store[:current_resource] = @license

        @license.touch(:last_validated_at) unless
          # Only touch if it's different. Large spikes in concurrent validation
          # requests needlessly update this, causing slow queries due to locks.
          @license.last_validated_at.to_i == Time.current.to_i

        BroadcastEventService.call(
          event: valid ? "license.validation.succeeded" : "license.validation.failed",
          account: current_account,
          resource: @license,
          meta: meta
        )
      end

      render jsonapi: @license, meta: meta
    end

    private

    def set_license
      @license = FindByAliasService.call(scope: current_account.licenses, identifier: params[:id], aliases: :key)
    end

    typed_parameters do
      options strict: true

      on :validate_by_id do
        param :meta, type: :hash, optional: true do
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
          end
        end
      end

      on :validate_by_key do
        param :meta, type: :hash do
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
          end
        end
      end
    end
  end
end

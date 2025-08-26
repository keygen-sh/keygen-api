# frozen_string_literal: true

module Api::V1
  class EntitlementsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_entitlement, only: %i[show update destroy]

    def index
      entitlements = apply_pagination(authorized_scope(apply_scopes(current_account.entitlements)))
      authorize! entitlements

      render jsonapi: entitlements
    end

    def show
      authorize! entitlement

      render jsonapi: entitlement
    end

    typed_params {
      format :jsonapi

      param :data, type: :hash do
        param :type, type: :string, inclusion: { in: %w[entitlement entitlements] }
        param :attributes, type: :hash do
          param :name, type: :string
          param :code, type: :string
          param :metadata, type: :hash, depth: { maximum: 2 }, allow_blank: true, optional: true
        end
        param :relationships, type: :hash, optional: true do
          Keygen.ee do |license|
            next unless
              license.entitled?(:environments)

            param :environment, type: :hash, optional: true do
              param :data, type: :hash, allow_nil: true do
                param :type, type: :string, inclusion: { in: %w[environment environments] }
                param :id, type: :uuid
              end
            end
          end
        end
      end
    }
    def create
      entitlement = current_account.entitlements.new(entitlement_params)
      authorize! entitlement

      if entitlement.save
        BroadcastEventService.call(
          event: 'entitlement.created',
          account: current_account,
          resource: entitlement,
        )

        render jsonapi: entitlement, status: :created, location: v1_account_entitlement_url(entitlement.account, entitlement)
      else
        render_unprocessable_resource entitlement
      end
    end

    typed_params {
      format :jsonapi

      param :data, type: :hash do
        param :type, type: :string, inclusion: { in: %w[entitlement entitlements] }
        param :id, type: :string, optional: true, noop: true
        param :attributes, type: :hash do
          param :name, type: :string, optional: true
          param :code, type: :string, optional: true
          param :metadata, type: :hash, depth: { maximum: 2 }, allow_blank: true, optional: true
        end
      end
    }
    def update
      authorize! entitlement

      if entitlement.update(entitlement_params)
        BroadcastEventService.call(
          event: 'entitlement.updated',
          account: current_account,
          resource: entitlement,
        )

        render jsonapi: entitlement
      else
        render_unprocessable_resource entitlement
      end
    end

    def destroy
      authorize! entitlement

      BroadcastEventService.call(
        event: 'entitlement.deleted',
        account: current_account,
        resource: entitlement,
      )

      entitlement.destroy
    end

    private

    attr_reader :entitlement

    def set_entitlement
      scoped_entitlements = authorized_scope(current_account.entitlements)

      @entitlement = FindByAliasService.call(scoped_entitlements, id: params[:id], aliases: :code)

      Current.resource = entitlement
    end
  end
end

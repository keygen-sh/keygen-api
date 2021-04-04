# frozen_string_literal: true

module Api::V1::Policies::Relationships
  class EntitlementsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_policy

    def index
      @policy_entitlements = policy_scope apply_scopes(@policy.policy_entitlements)
      authorize @policy_entitlements

      render jsonapi: @policy_entitlements
    end

    def show
      @policy_entitlement = @policy.policy_entitlements.find params[:id]
      authorize @policy_entitlement

      render jsonapi: @policy_entitlement
    end

    def create
      @policy_entitlement = @policy.policy_entitlements.new entitlement_params.merge(account: current_account)
      authorize @policy_entitlement

      if @policy_entitlement.save
        CreateWebhookEventService.new(
          event: 'policy.entitlement.created',
          account: current_account,
          resource: @policy_entitlement
        ).execute

        render jsonapi: @policy_entitlement, status: :created, location: v1_account_policy_entitlement_url(@policy_entitlement.account, @policy_entitlement.policy, @policy_entitlement)
      else
        render_unprocessable_resource @policy_entitlement
      end
    end

    def destroy
      @policy_entitlement = @policy.policy_entitlements.find params[:id]
      authorize @policy_entitlement

      CreateWebhookEventService.new(
        event: 'policy.entitlement.deleted',
        account: current_account,
        resource: @policy_entitlement
      ).execute

      @policy_entitlement.destroy
    end

    private

    def set_policy
      @policy = current_account.policies.find params[:policy_id]

      Keygen::Store::Request.store[:current_resource] = @policy
    end

    typed_parameters transform: true do
      options strict: true

      on :create do
        param :data, type: :hash do
          param :type, type: :string, inclusion: %w[policy.entitlement policy.entitlements]
          param :relationships, type: :hash do
            param :entitlement, type: :hash do
              param :data, type: :hash do
                param :type, type: :string, inclusion: %w[entitlement entitlements]
                param :id, type: :string
              end
            end
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module Api::V1::Policies::Relationships
  class LicensesController < Api::V1::BaseController
    has_scope :suspended
    has_scope :product
    has_scope :user

    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_policy

    # GET /policies/1/licenses
    def index
      @licenses = policy_scope apply_scopes(@policy.licenses)
      authorize @licenses

      render jsonapi: @licenses
    end

    # GET /policies/1/licenses/1
    def show
      @license = FindByAliasService.new(@policy.licenses, params[:id], aliases: :key).call
      authorize @license

      render jsonapi: @license
    end

    private

    def set_policy
      @policy = current_account.policies.find params[:policy_id]
      authorize @policy, :show?

      Keygen::Store::Request.store[:current_resource] = @policy
    end
  end
end

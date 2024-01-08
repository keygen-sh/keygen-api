# frozen_string_literal: true

module Api::V1::Policies::Relationships
  class LicensesController < Api::V1::BaseController
    has_scope(:product) { |c, s, v| s.for_product(v) }
    has_scope(:user) { |c, s, v| s.for_user(v) }
    has_scope :suspended

    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_policy

    authorize :policy

    def index
      licenses = apply_pagination(authorized_scope(apply_scopes(policy.licenses)).preload(:role, :policy, :owner))
      authorize! licenses,
        with: Policies::LicensePolicy

      render jsonapi: licenses
    end

    def show
      license = FindByAliasService.call(policy.licenses, id: params[:id], aliases: :key)
      authorize! license,
        with: Policies::LicensePolicy

      render jsonapi: license
    end

    private

    attr_reader :policy

    def set_policy
      scoped_policies = authorized_scope(current_account.policies)

      @policy = scoped_policies.find(params[:policy_id])

      Current.resource = policy
    end
  end
end

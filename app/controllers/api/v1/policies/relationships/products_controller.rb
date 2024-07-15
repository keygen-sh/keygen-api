# frozen_string_literal: true

module Api::V1::Policies::Relationships
  class ProductsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate!
    before_action :set_policy

    authorize :policy

    def show
      product = policy.product
      authorize! product,
        with: Policies::ProductPolicy

      render jsonapi: product
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

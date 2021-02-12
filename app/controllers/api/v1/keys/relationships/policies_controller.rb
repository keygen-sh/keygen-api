# frozen_string_literal: true

module Api::V1::Keys::Relationships
  class PoliciesController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_key

    # GET /keys/1/policy
    def show
      @policy = @key.policy
      authorize @policy

      render jsonapi: @policy
    end

    private

    def set_key
      @key = current_account.keys.find params[:key_id]
      authorize @key, :show?

      Keygen::Store::Request.store[:current_resource] = @key
    end
  end
end

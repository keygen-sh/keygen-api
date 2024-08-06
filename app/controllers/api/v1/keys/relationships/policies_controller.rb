# frozen_string_literal: true

module Api::V1::Keys::Relationships
  class PoliciesController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate!
    before_action :set_key

    authorize :key

    def show
      policy = key.policy
      authorize! policy,
        with: Keys::PolicyPolicy

      render jsonapi: policy
    end

    private

    attr_reader :key

    def set_key
      scoped_keys = authorized_scope(current_account.keys)

      @key = scoped_keys.find(params[:key_id])

      Current.resource = key
    end
  end
end

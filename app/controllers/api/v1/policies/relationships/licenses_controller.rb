module Api::V1::Policies::Relationships
  class LicensesController < Api::V1::BaseController
    has_scope :product
    has_scope :user

    before_action :scope_to_current_account!
    before_action :authenticate_with_token!
    before_action :set_policy

    # GET /policies/1/licenses
    def index
      @licenses = policy_scope apply_scopes(@policy.licenses).all
      authorize @licenses

      render jsonapi: @licenses
    end

    # GET /policies/1/licenses/1
    def show
      @license = @policy.licenses.find params[:id]
      authorize @license

      render jsonapi: @license
    end

    private

    def set_policy
      @policy = current_account.policies.find params[:policy_id]
      authorize @policy, :show?
    end
  end
end

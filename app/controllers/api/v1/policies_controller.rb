module Api::V1
  class PoliciesController < Api::V1::BaseController
    has_scope :product

    before_action :scope_to_current_account!
    before_action :authenticate_with_token!
    before_action :set_policy, only: [:show, :update, :destroy]

    # GET /policies
    def index
      @policies = policy_scope apply_scopes(current_account.policies).all
      authorize @policies

      render jsonapi: @policies
    end

    # GET /policies/1
    def show
      authorize @policy

      render jsonapi: @policy
    end

    # POST /policies
    def create
      @policy = current_account.policies.new policy_params
      authorize @policy

      if @policy.save
        CreateWebhookEventService.new(
          event: "policy.created",
          account: current_account,
          resource: @policy
        ).execute

        render jsonapi: @policy, status: :created, location: v1_account_policy_url(@policy.account, @policy)
      else
        render_unprocessable_resource @policy
      end
    end

    # PATCH/PUT /policies/1
    def update
      authorize @policy

      if @policy.update(policy_params)
        CreateWebhookEventService.new(
          event: "policy.updated",
          account: current_account,
          resource: @policy
        ).execute

        render jsonapi: @policy
      else
        render_unprocessable_resource @policy
      end
    end

    # DELETE /policies/1
    def destroy
      authorize @policy

      CreateWebhookEventService.new(
        event: "policy.deleted",
        account: current_account,
        resource: @policy
      ).execute

      @policy.destroy
    end

    private

    def set_policy
      @policy = current_account.policies.find params[:id]
    end

    typed_parameters transform: true do
      options strict: true

      on :create do
        param :data, type: :hash do
          param :type, type: :string, inclusion: %w[policy policies]
          param :attributes, type: :hash do
            param :encrypted, type: :boolean, optional: true
            param :use_pool, type: :boolean, optional: true
            param :name, type: :string, optional: true
            param :price, type: :integer, optional: true
            param :duration, type: :integer, optional: true
            param :strict, type: :boolean, optional: true
            param :recurring, type: :boolean, optional: true
            param :floating, type: :boolean, optional: true
            param :protected, type: :boolean, optional: true
            param :max_machines, type: :integer, optional: true
            param :metadata, type: :hash, optional: true
          end
          param :relationships, type: :hash do
            param :product, type: :hash do
              param :data, type: :hash do
                param :type, type: :string, inclusion: %w[product products]
                param :id, type: :string
              end
            end
          end
        end
      end

      on :update do
        param :data, type: :hash do
          param :type, type: :string, inclusion: %w[policy policies]
          param :attributes, type: :hash do
            param :name, type: :string, optional: true
            param :price, type: :integer, optional: true
            param :duration, type: :integer, optional: true
            param :strict, type: :boolean, optional: true
            param :recurring, type: :boolean, optional: true
            param :floating, type: :boolean, optional: true
            param :protected, type: :boolean, optional: true
            param :max_machines, type: :integer, optional: true
            param :metadata, type: :hash, optional: true
          end
        end
      end
    end
  end
end

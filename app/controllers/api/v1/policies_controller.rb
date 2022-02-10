# frozen_string_literal: true

module Api::V1
  class PoliciesController < Api::V1::BaseController
    has_scope(:product) { |c, s, v| s.for_product(v) }

    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_policy, only: [:show, :update, :destroy]

    # GET /policies
    def index
      @policies = policy_scope apply_scopes(current_account.policies)
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
        BroadcastEventService.call(
          event: "policy.created",
          account: current_account,
          resource: @policy
        )

        render jsonapi: @policy, status: :created, location: v1_account_policy_url(@policy.account, @policy)
      else
        render_unprocessable_resource @policy
      end
    end

    # PATCH/PUT /policies/1
    def update
      authorize @policy

      if @policy.update(policy_params)
        BroadcastEventService.call(
          event: "policy.updated",
          account: current_account,
          resource: @policy
        )

        render jsonapi: @policy
      else
        render_unprocessable_resource @policy
      end
    end

    # DELETE /policies/1
    def destroy
      authorize @policy

      BroadcastEventService.call(
        event: "policy.deleted",
        account: current_account,
        resource: @policy
      )

      @policy.destroy_async
    end

    private

    def set_policy
      @policy = current_account.policies.find params[:id]

      Current.resource = @policy
    end

    typed_parameters format: :jsonapi do
      options strict: true

      on :create do
        param :data, type: :hash do
          param :type, type: :string, inclusion: %w[policy policies]
          param :attributes, type: :hash do
            param :scheme, type: :string, optional: true
            param :encrypted, type: :boolean, optional: true
            param :use_pool, type: :boolean, optional: true
            param :name, type: :string, optional: true
            param :duration, type: :integer, optional: true, allow_nil: true
            param :strict, type: :boolean, optional: true
            param :floating, type: :boolean, optional: true
            param :protected, type: :boolean, optional: true
            param :concurrent, type: :boolean, optional: true
            param :max_machines, type: :integer, optional: true, allow_nil: true
            param :max_cores, type: :integer, optional: true, allow_nil: true
            param :max_uses, type: :integer, optional: true, allow_nil: true
            param :fingerprint_uniqueness_strategy, type: :string, optional: true
            param :fingerprint_matching_strategy, type: :string, optional: true
            param :expiration_strategy, type: :string, optional: true
            param :expiration_basis, type: :string, optional: true
            param :authentication_strategy, type: :string, optional: true
            param :require_product_scope, type: :boolean, optional: true
            param :require_policy_scope, type: :boolean, optional: true
            param :require_machine_scope, type: :boolean, optional: true
            param :require_fingerprint_scope, type: :boolean, optional: true
            param :require_check_in, type: :boolean, optional: true
            param :check_in_interval, type: :string, optional: true, allow_nil: true
            param :check_in_interval_count, type: :integer, optional: true, allow_nil: true
            param :heartbeat_duration, type: :integer, optional: true, allow_nil: true
            param :heartbeat_cull_strategy, type: :string, optional: true
            param :metadata, type: :hash, allow_non_scalars: true, optional: true
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
          param :id, type: :string, inclusion: [controller.params[:id]], optional: true, transform: -> (k, v) { [] }
          param :attributes, type: :hash do
            param :name, type: :string, optional: true
            param :duration, type: :integer, optional: true, allow_nil: true
            param :strict, type: :boolean, optional: true
            param :floating, type: :boolean, optional: true
            param :protected, type: :boolean, optional: true
            param :concurrent, type: :boolean, optional: true
            param :max_machines, type: :integer, optional: true, allow_nil: true
            param :max_cores, type: :integer, optional: true, allow_nil: true
            param :max_uses, type: :integer, optional: true, allow_nil: true
            param :fingerprint_uniqueness_strategy, type: :string, optional: true
            param :fingerprint_matching_strategy, type: :string, optional: true
            param :expiration_strategy, type: :string, optional: true
            param :expiration_basis, type: :string, optional: true
            param :authentication_strategy, type: :string, optional: true
            param :require_product_scope, type: :boolean, optional: true
            param :require_policy_scope, type: :boolean, optional: true
            param :require_machine_scope, type: :boolean, optional: true
            param :require_fingerprint_scope, type: :boolean, optional: true
            param :require_check_in, type: :boolean, optional: true
            param :check_in_interval, type: :string, optional: true, allow_nil: true
            param :check_in_interval_count, type: :integer, optional: true, allow_nil: true
            param :heartbeat_duration, type: :integer, optional: true, allow_nil: true
            param :heartbeat_cull_strategy, type: :string, optional: true
            param :metadata, type: :hash, allow_non_scalars: true, optional: true
          end
        end
      end
    end
  end
end

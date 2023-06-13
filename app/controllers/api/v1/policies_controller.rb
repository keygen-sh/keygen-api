# frozen_string_literal: true

module Api::V1
  class PoliciesController < Api::V1::BaseController
    has_scope(:product) { |c, s, v| s.for_product(v) }

    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_policy, only: %i[show update destroy]

    def index
      policies = apply_pagination(authorized_scope(apply_scopes(current_account.policies)))
      authorize! policies

      render jsonapi: policies
    end

    def show
      authorize! policy

      render jsonapi: policy
    end

    typed_params {
      format :jsonapi

      param :data, type: :hash do
        param :type, type: :string, inclusion: { in: %w[policy policies] }
        param :attributes, type: :hash do
          param :scheme, type: :string, optional: true
          param :encrypted, type: :boolean, optional: true
          param :use_pool, type: :boolean, optional: true
          param :name, type: :string, optional: true
          param :duration, type: :integer, allow_nil: true, optional: true
          param :strict, type: :boolean, optional: true
          param :floating, type: :boolean, optional: true
          param :protected, type: :boolean, optional: true
          param :concurrent, type: :boolean, optional: true, if: -> { current_api_version == '1.0' || current_api_version == '1.1' }
          param :max_machines, type: :integer, allow_nil: true, optional: true
          param :max_processes, type: :integer, allow_nil: true, optional: true
          param :max_cores, type: :integer, allow_nil: true, optional: true
          param :max_uses, type: :integer, allow_nil: true, optional: true
          param :fingerprint_uniqueness_strategy, type: :string, optional: true
          param :fingerprint_matching_strategy, type: :string, optional: true
          param :expiration_strategy, type: :string, optional: true
          param :expiration_basis, type: :string, optional: true
          param :transfer_strategy, type: :string, optional: true
          param :authentication_strategy, type: :string, optional: true
          param :leasing_strategy, type: :string, optional: true
          param :overage_strategy, type: :string, optional: true
          param :require_product_scope, type: :boolean, optional: true
          param :require_policy_scope, type: :boolean, optional: true
          param :require_machine_scope, type: :boolean, optional: true
          param :require_fingerprint_scope, type: :boolean, optional: true
          param :require_user_scope, type: :boolean, optional: true
          param :require_checksum_scope, type: :boolean, optional: true
          param :require_version_scope, type: :boolean, optional: true
          param :require_check_in, type: :boolean, optional: true
          param :check_in_interval, type: :string, allow_nil: true, optional: true
          param :check_in_interval_count, type: :integer, allow_nil: true, optional: true
          param :heartbeat_duration, type: :integer, allow_nil: true, optional: true
          param :heartbeat_cull_strategy, type: :string, optional: true
          param :heartbeat_resurrection_strategy, type: :string, optional: true
          param :heartbeat_basis, type: :string, optional: true
          param :require_heartbeat, type: :boolean, optional: true
          param :metadata, type: :metadata, allow_blank: true, optional: true
        end
        param :relationships, type: :hash do
          param :product, type: :hash do
            param :data, type: :hash do
              param :type, type: :string, inclusion: { in: %w[product products] }
              param :id, type: :string
            end
          end

          Keygen.ee do |license|
            next unless
              license.entitled?(:environments)

            param :environment, type: :hash, optional: true do
              param :data, type: :hash, allow_nil: true do
                param :type, type: :string, inclusion: { in: %w[environment environments] }
                param :id, type: :string
              end
            end
          end
        end
      end
    }
    def create
      policy = current_account.policies.new(api_version: current_api_version, **policy_params)
      authorize! policy

      if policy.save
        BroadcastEventService.call(
          event: 'policy.created',
          account: current_account,
          resource: policy,
        )

        render jsonapi: policy, status: :created, location: v1_account_policy_url(policy.account, policy)
      else
        render_unprocessable_resource policy
      end
    end

    typed_params {
      format :jsonapi

      param :data, type: :hash do
        param :type, type: :string, inclusion: { in: %w[policy policies] }
        param :id, type: :string, optional: true, noop: true
        param :attributes, type: :hash do
          param :name, type: :string, optional: true
          param :duration, type: :integer, allow_nil: true, optional: true
          param :strict, type: :boolean, optional: true
          param :floating, type: :boolean, optional: true
          param :protected, type: :boolean, optional: true
          param :concurrent, type: :boolean, optional: true, if: -> { current_api_version == '1.0' || current_api_version == '1.1' }
          param :max_machines, type: :integer, allow_nil: true, optional: true
          param :max_processes, type: :integer, allow_nil: true, optional: true
          param :max_cores, type: :integer, allow_nil: true, optional: true
          param :max_uses, type: :integer, allow_nil: true, optional: true
          param :fingerprint_uniqueness_strategy, type: :string, optional: true
          param :fingerprint_matching_strategy, type: :string, optional: true
          param :expiration_strategy, type: :string, optional: true
          param :expiration_basis, type: :string, optional: true
          param :transfer_strategy, type: :string, optional: true
          param :authentication_strategy, type: :string, optional: true
          param :leasing_strategy, type: :string, optional: true
          param :overage_strategy, type: :string, optional: true
          param :require_product_scope, type: :boolean, optional: true
          param :require_policy_scope, type: :boolean, optional: true
          param :require_machine_scope, type: :boolean, optional: true
          param :require_fingerprint_scope, type: :boolean, optional: true
          param :require_user_scope, type: :boolean, optional: true
          param :require_checksum_scope, type: :boolean, optional: true
          param :require_version_scope, type: :boolean, optional: true
          param :require_check_in, type: :boolean, optional: true
          param :check_in_interval, type: :string, allow_nil: true, optional: true
          param :check_in_interval_count, type: :integer, allow_nil: true, optional: true
          param :heartbeat_duration, type: :integer, allow_nil: true, optional: true
          param :heartbeat_cull_strategy, type: :string, optional: true
          param :heartbeat_resurrection_strategy, type: :string, optional: true
          param :heartbeat_basis, type: :string, optional: true
          param :require_heartbeat, type: :boolean, optional: true
          param :metadata, type: :metadata, allow_blank: true, optional: true
        end
      end
    }
    def update
      authorize! policy

      if policy.update(policy_params)
        BroadcastEventService.call(
          event: 'policy.updated',
          account: current_account,
          resource: policy,
        )

        render jsonapi: policy
      else
        render_unprocessable_resource policy
      end
    end

    def destroy
      authorize! policy

      BroadcastEventService.call(
        event: 'policy.deleted',
        account: current_account,
        resource: policy,
      )

      policy.destroy_async
    end

    private

    attr_reader :policy

    def set_policy
      scoped_policies = authorized_scope(current_account.policies)

      @policy = scoped_policies.find(params[:id])

      Current.resource = policy
    end
  end
end

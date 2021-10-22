# frozen_string_literal: true

module Api::V1
  class LicensesController < Api::V1::BaseController
    has_scope(:metadata, type: :hash, only: :index) { |c, s, v| s.with_metadata(v) }
    has_scope(:product) { |c, s, v| s.for_product(v) }
    has_scope(:policy) { |c, s, v| s.for_policy(v) }
    has_scope(:user) { |c, s, v| s.for_user(v) }
    has_scope(:machine) { |c, s, v| s.for_machine(v) }
    has_scope(:status) { |c, s, v| s.with_status(v) }
    has_scope :suspended
    has_scope :expiring
    has_scope :expired
    has_scope :unassigned

    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_license, only: [:show, :update, :destroy]

    # GET /licenses
    def index
      @licenses = policy_scope apply_scopes(current_account.licenses.preload(:policy))
      authorize @licenses

      render jsonapi: @licenses
    end

    # GET /licenses/1
    def show
      authorize @license

      render jsonapi: @license
    end

    # POST /licenses
    def create
      @license = current_account.licenses.new license_params
      authorize @license

      if @license.save
        BroadcastEventService.call(
          event: "license.created",
          account: current_account,
          resource: @license
        )

        render jsonapi: @license, status: :created, location: v1_account_license_url(@license.account, @license)
      else
        render_unprocessable_resource @license
      end
    end

    # PATCH/PUT /licenses/1
    def update
      authorize @license

      if @license.update(license_params)
        BroadcastEventService.call(
          event: "license.updated",
          account: current_account,
          resource: @license
        )

        render jsonapi: @license
      else
        render_unprocessable_resource @license
      end
    end

    # DELETE /licenses/1
    def destroy
      authorize @license

      BroadcastEventService.call(
        event: "license.deleted",
        account: current_account,
        resource: @license
      )

      @license.destroy_async
    end

    private

    def set_license
      @license = FindByAliasService.call(scope: current_account.licenses, identifier: params[:id], aliases: :key)

      Keygen::Store::Request.store[:current_resource] = @license
    end

    typed_parameters format: :jsonapi do
      options strict: true

      on :create do
        param :data, type: :hash do
          param :type, type: :string, inclusion: %w[license licenses]
          if current_bearer&.has_role?(:admin, :developer, :sales_agent, :product)
            param :id, type: :string, optional: true
          end
          param :attributes, type: :hash, optional: true do
            param :name, type: :string, optional: true
            param :key, type: :string, optional: true
            if current_bearer&.has_role?(:admin, :developer, :sales_agent, :product)
              param :protected, type: :boolean, optional: true
              param :expiry, type: :datetime, optional: true, coerce: true, allow_nil: true
              param :suspended, type: :boolean, optional: true
              param :max_machines, type: :integer, optional: true, allow_nil: true
              param :max_cores, type: :integer, optional: true, allow_nil: true
              param :max_uses, type: :integer, optional: true, allow_nil: true
            end
            param :metadata, type: :hash, allow_non_scalars: true, optional: true
          end
          param :relationships, type: :hash do
            param :policy, type: :hash do
              param :data, type: :hash do
                param :type, type: :string, inclusion: %w[policy policies]
                param :id, type: :string
              end
            end
            param :user, type: :hash, optional: true do
              param :data, type: :hash, allow_nil: true do
                param :type, type: :string, inclusion: %w[user users]
                param :id, type: :string
              end
            end
          end
        end
      end

      on :update do
        param :data, type: :hash do
          param :type, type: :string, inclusion: %w[license licenses]
          param :id, type: :string, inclusion: [controller.params[:id]], optional: true, transform: -> (k, v) { [] }
          param :attributes, type: :hash do
            param :name, type: :string, optional: true, allow_nil: true
            if current_bearer&.has_role?(:admin, :developer, :sales_agent, :support_agent, :product)
              param :expiry, type: :datetime, optional: true, coerce: true, allow_nil: true
              param :protected, type: :boolean, optional: true
              param :suspended, type: :boolean, optional: true
              param :metadata, type: :hash, allow_non_scalars: true, optional: true
              param :max_machines, type: :integer, optional: true, allow_nil: true
              param :max_cores, type: :integer, optional: true, allow_nil: true
              param :max_uses, type: :integer, optional: true, allow_nil: true
            end
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module Api::V1
  class KeysController < Api::V1::BaseController
    has_scope(:product) { |c, s, v| s.for_product(v) }
    has_scope(:policy) { |c, s, v| s.for_policy(v) }

    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_key, only: [:show, :update, :destroy]

    # GET /keys
    def index
      @keys = policy_scope(apply_scopes(current_account.keys)).preload(:product)
      authorize @keys

      render jsonapi: @keys
    end

    # GET /keys/1
    def show
      authorize @key

      render jsonapi: @key
    end

    # POST /keys
    def create
      @key = current_account.keys.new key_params
      authorize @key

      if @key.save
        BroadcastEventService.call(
          event: "key.created",
          account: current_account,
          resource: @key
        )

        render jsonapi: @key, status: :created, location: v1_account_key_url(@key.account, @key)
      else
        render_unprocessable_resource @key
      end
    end

    # PATCH/PUT /keys/1
    def update
      authorize @key

      if @key.update(key_params)
        BroadcastEventService.call(
          event: "key.updated",
          account: current_account,
          resource: @key
        )

        render jsonapi: @key
      else
        render_unprocessable_resource @key
      end
    end

    # DELETE /keys/1
    def destroy
      authorize @key

      BroadcastEventService.call(
        event: "key.deleted",
        account: current_account,
        resource: @key
      )

      @key.destroy_async
    end

    private

    def set_key
      @key = current_account.keys.find params[:id]

      Current.resource = @key
    end

    typed_parameters format: :jsonapi do
      options strict: true

      on :create do
        param :data, type: :hash do
          param :type, type: :string, inclusion: %w[key keys]
          param :attributes, type: :hash do
            param :key, type: :string
          end
          param :relationships, type: :hash do
            param :policy, type: :hash do
              param :data, type: :hash do
                param :type, type: :string, inclusion: %w[policy policies]
                param :id, type: :string
              end
            end
          end
        end
      end

      on :update do
        param :data, type: :hash do
          param :type, type: :string, inclusion: %w[key keys]
          param :id, type: :string, inclusion: [controller.params[:id]], optional: true, transform: -> (k, v) { [] }
          param :attributes, type: :hash do
            param :key, type: :string, optional: true
          end
        end
      end
    end
  end
end

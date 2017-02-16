module Api::V1
  class KeysController < Api::V1::BaseController
    has_scope :product
    has_scope :policy

    before_action :scope_to_current_account!
    before_action :authenticate_with_token!
    before_action :set_key, only: [:show, :update, :destroy]

    # GET /keys
    def index
      @keys = policy_scope apply_scopes(current_account.keys).all
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
        CreateWebhookEventService.new(
          event: "key.created",
          account: current_account,
          resource: @key
        ).execute

        render jsonapi: @key, status: :created, location: v1_account_key_url(@key.account, @key)
      else
        render_unprocessable_resource @key
      end
    end

    # PATCH/PUT /keys/1
    def update
      authorize @key

      if @key.update(key_params)
        CreateWebhookEventService.new(
          event: "key.updated",
          account: current_account,
          resource: @key
        ).execute

        render jsonapi: @key
      else
        render_unprocessable_resource @key
      end
    end

    # DELETE /keys/1
    def destroy
      authorize @key

      CreateWebhookEventService.new(
        event: "key.deleted",
        account: current_account,
        resource: @key
      ).execute

      @key.destroy
    end

    private

    def set_key
      @key = current_account.keys.find params[:id]
    end

    typed_parameters transform: true do
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
          param :id, type: :string, inclusion: [context.params[:id]], optional: true, transform: -> (k, v) { [] }
          param :attributes, type: :hash do
            param :key, type: :string, optional: true
          end
        end
      end
    end
  end
end

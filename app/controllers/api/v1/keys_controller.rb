module Api::V1
  class KeysController < Api::V1::BaseController
    has_scope :policy

    before_action :scope_to_current_account!
    before_action :authenticate_with_token!
    before_action :set_key, only: [:show, :update, :destroy]

    # GET /keys
    def index
      @keys = policy_scope apply_scopes(current_account.keys).all
      authorize @keys

      render json: @keys
    end

    # GET /keys/1
    def show
      render_not_found and return unless @key

      authorize @key

      render json: @key
    end

    # POST /keys
    def create
      policy = current_account.policies.find_by_hashid key_parameters[:policy]

      @key = current_account.keys.new key_parameters.merge(policy: policy)
      authorize @key

      if @key.save
        CreateWebhookEventService.new(
          event: "key.created",
          account: current_account,
          resource: @key
        ).execute

        render json: @key, status: :created, location: v1_account_key_url(@key.account, @key)
      else
        render_unprocessable_resource @key
      end
    end

    # PATCH/PUT /keys/1
    def update
      render_not_found and return unless @key

      authorize @key

      if @key.update(key_parameters)
        CreateWebhookEventService.new(
          event: "key.updated",
          account: current_account,
          resource: @key
        ).execute

        render json: @key
      else
        render_unprocessable_resource @key
      end
    end

    # DELETE /keys/1
    def destroy
      render_not_found and return unless @key

      authorize @key

      CreateWebhookEventService.new(
        event: "key.deleted",
        account: current_account,
        resource: @key
      ).execute

      @key.destroy
    end

    private

    attr_reader :parameters

    def set_key
      @key = current_account.keys.find_by_hashid params[:id]
    end

    def key_parameters
      parameters[:key]
    end

    def parameters
      @parameters ||= TypedParameters.build self do
        options strict: true

        on :create do
          param :key, type: :hash do
            param :policy, type: :string
            param :key, type: :string
          end
        end

        on :update do
          param :key, type: :hash do
            param :key, type: :string, optional: true
          end
        end
      end
    end
  end
end

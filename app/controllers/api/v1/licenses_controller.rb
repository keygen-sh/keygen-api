module Api::V1
  class LicensesController < Api::V1::BaseController
    has_scope :suspended
    has_scope :expired
    has_scope :product
    has_scope :policy
    has_scope :user
    has_scope :machine

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
        CreateWebhookEventService.new(
          event: "license.created",
          account: current_account,
          resource: @license
        ).execute

        render jsonapi: @license, status: :created, location: v1_account_license_url(@license.account, @license)
      else
        render_unprocessable_resource @license
      end
    end

    # PATCH/PUT /licenses/1
    def update
      authorize @license

      if @license.update(license_params)
        CreateWebhookEventService.new(
          event: "license.updated",
          account: current_account,
          resource: @license
        ).execute

        render jsonapi: @license
      else
        render_unprocessable_resource @license
      end
    end

    # DELETE /licenses/1
    def destroy
      authorize @license

      CreateWebhookEventService.new(
        event: "license.deleted",
        account: current_account,
        resource: @license
      ).execute

      @license.destroy_async
    end

    private

    def set_license
      @license =
        if params[:id] =~ UUID_REGEX
          current_account.licenses.find_by id: params[:id]
        else
          current_account.licenses.find_by key: params[:id]
        end

      raise Keygen::Error::NotFoundError.new(model: License.name, id: params[:id]) if @license.nil?
    end

    typed_parameters transform: true do
      options strict: true

      on :create do
        param :data, type: :hash do
          param :type, type: :string, inclusion: %w[license licenses]
          param :attributes, type: :hash, optional: true do
            param :name, type: :string, optional: true
            param :key, type: :string, optional: true
            if current_bearer&.role? :admin or current_bearer&.role? :product
              param :protected, type: :boolean, optional: true
              param :expiry, type: :datetime, optional: true, coerce: true, allow_nil: true
              param :suspended, type: :boolean, optional: true
            end
            param :metadata, type: :hash, optional: true
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
            if current_bearer&.role? :admin or current_bearer&.role? :product
              param :expiry, type: :datetime, optional: true, coerce: true, allow_nil: true
              param :protected, type: :boolean, optional: true
              param :suspended, type: :boolean, optional: true
              param :metadata, type: :hash, optional: true
            end
          end
        end
      end
    end
  end
end

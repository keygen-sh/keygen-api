# frozen_string_literal: true

module Api::V1
  class KeysController < Api::V1::BaseController
    has_scope(:product) { |c, s, v| s.for_product(v) }
    has_scope(:policy) { |c, s, v| s.for_policy(v) }

    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_key, only: %i[show update destroy]

    def index
      keys = apply_pagination(authorized_scope(apply_scopes(current_account.keys)).preload(:product))
      authorize! keys

      render jsonapi: keys
    end

    def show
      authorize! key

      render jsonapi: key
    end

    typed_params {
      format :jsonapi

      param :data, type: :hash do
        param :type, type: :string, inclusion: { in: %w[key keys] }
        param :attributes, type: :hash do
          param :key, type: :string
        end
        param :relationships, type: :hash do
          param :policy, type: :hash do
            param :data, type: :hash do
              param :type, type: :string, inclusion: { in: %w[policy policies] }
              param :id, type: :uuid
            end
          end

          Keygen.ee do |license|
            next unless
              license.entitled?(:environments)

            param :environment, type: :hash, optional: true do
              param :data, type: :hash, allow_nil: true do
                param :type, type: :string, inclusion: { in: %w[environment environments] }
                param :id, type: :uuid
              end
            end
          end
        end
      end
    }
    def create
      key = current_account.keys.new(key_params)
      authorize! key

      if key.save
        BroadcastEventService.call(
          event: 'key.created',
          account: current_account,
          resource: key,
        )

        render jsonapi: key, status: :created, location: v1_account_key_url(key.account, key)
      else
        render_unprocessable_resource key
      end
    end

    typed_params {
      format :jsonapi

      param :data, type: :hash do
        param :type, type: :string, inclusion: { in: %w[key keys] }
        param :id, type: :string, optional: true, noop: true
        param :attributes, type: :hash do
          param :key, type: :string, optional: true
        end
      end
    }
    def update
      authorize! key

      if key.update(key_params)
        BroadcastEventService.call(
          event: 'key.updated',
          account: current_account,
          resource: key,
        )

        render jsonapi: key
      else
        render_unprocessable_resource key
      end
    end

    def destroy
      authorize! key

      BroadcastEventService.call(
        event: 'key.deleted',
        account: current_account,
        resource: key,
      )

      key.destroy
    end

    private

    attr_reader :key

    def set_key
      scoped_keys = authorized_scope(current_account.keys)

      @key = scoped_keys.find(params[:id])

      Current.resource = key
    end
  end
end

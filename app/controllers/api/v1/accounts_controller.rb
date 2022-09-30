# frozen_string_literal: true

module Api::V1
  class AccountsController < Api::V1::BaseController
    before_action :scope_to_current_account!, only: %i[show update destroy]
    before_action :authenticate_with_token!, only: %i[show update destroy]
    before_action :set_account, only: %i[show update destroy]

    def show
      authorize! account

      render jsonapi: account
    end

    def create
      account = Account.new account_params.merge(referral_id: account_meta[:referral])
      authorize! account

      if account.save
        render jsonapi: account, status: :created, location: v1_account_url(account)
      else
        render_unprocessable_resource account
      end
    end

    def update
      authorize! account

      if account.update(account_params)
        BroadcastEventService.call(
          event: 'account.updated',
          account: account,
          resource: account,
        )

        render jsonapi: account
      else
        render_unprocessable_resource account
      end
    end

    def destroy
      authorize! account

      account.destroy_async
    end

    private

    attr_reader :account

    def set_account
      @account = current_account

      Resource.current = account
    end

    typed_parameters format: :jsonapi do
      options strict: true

      on :create do
        param :data, type: :hash do
          param :type, type: :string, inclusion: %w[account accounts]
          param :attributes, type: :hash, optional: true do
            param :name, type: :string, optional: true
            param :slug, type: :string, optional: true
            param :protected, type: :boolean, optional: true
          end
          param :relationships, type: :hash do
            param :plan, type: :hash do
              param :data, type: :hash do
                param :type, type: :string, inclusion: %w[plan plans]
                param :id, type: :string
              end
            end
            param :admins, type: :hash do
              param :data, type: :array do
                items type: :hash do
                  param :type, type: :string, inclusion: %w[user users]
                  param :attributes, type: :hash do
                    param :email, type: :string
                    param :password, type: :string
                    param :first_name, type: :string, optional: true
                    param :last_name, type: :string, optional: true
                    param :metadata, type: :hash, allow_non_scalars: true, optional: true
                    param :role, type: :string, optional: true, transform: -> (k, v) { [] }
                  end
                  param :relationships, type: :hash, optional: true, transform: -> (k, v) { [] } do
                    param :group, type: :hash, optional: true do
                      param :data, type: :hash, allow_nil: true do
                        param :type, type: :string, inclusion: %w[group groups]
                        param :id, type: :string
                      end
                    end
                  end
                end
              end
            end
          end
        end
        param :meta, type: :hash, optional: true do
          param :referral, type: :string, optional: true
        end
      end

      on :update do
        param :data, type: :hash do
          param :type, type: :string, inclusion: %w[account accounts]
          param :id, type: :string, optional: true, transform: -> (k, v) { [] }
          param :attributes, type: :hash do
            param :name, type: :string, optional: true
            param :slug, type: :string, optional: true
            param :api_version, type: :string, inclusion: RequestMigrations.supported_versions, optional: true
            param :protected, type: :boolean, optional: true
          end
        end
      end
    end
  end
end

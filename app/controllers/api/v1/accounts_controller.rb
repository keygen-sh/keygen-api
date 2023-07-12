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

    typed_params {
      format :jsonapi

      param :data, type: :hash do
        param :type, type: :string, inclusion: { in: %w[account accounts] }
        param :attributes, type: :hash, optional: true do
          param :name, type: :string, optional: true
          param :slug, type: :string, optional: true
          param :protected, type: :boolean, optional: true
        end
        param :relationships, type: :hash do
          param :plan, type: :hash do
            param :data, type: :hash do
              param :type, type: :string, inclusion: { in: %w[plan plans] }
              param :id, type: :uuid
            end
          end
          param :admins, type: :hash, as: :users do
            param :data, type: :array do
              items type: :hash do
                param :type, type: :string, inclusion: { in: %w[user users] }
                param :attributes, type: :hash do
                  param :email, type: :string
                  param :password, type: :string, allow_blank: true, allow_nil: true, optional: true
                  param :first_name, type: :string, allow_blank: true, allow_nil: true, optional: true
                  param :last_name, type: :string, allow_blank: true, allow_nil: true, optional: true
                  param :metadata, type: :metadata, allow_blank: true, optional: true
                  param :role, type: :string, inclusion: { in: %w[admin] }, optional: true, noop: true
                end
              end
            end
          end
        end
      end
      param :meta, type: :hash, optional: true do
        param :referral, type: :string, optional: true
      end
    }
    def create
      account = Account.new account_params.merge(referral_id: account_meta[:referral])
      authorize! account

      if account.save
        render jsonapi: account, status: :created, location: v1_account_url(account)
      else
        render_unprocessable_resource account
      end
    end

    typed_params {
      format :jsonapi

      param :data, type: :hash do
        param :type, type: :string, inclusion: { in: %w[account accounts] }
        param :id, type: :uuid, optional: true, noop: true
        param :attributes, type: :hash do
          param :name, type: :string, optional: true
          param :slug, type: :string, optional: true
          param :api_version, type: :string, inclusion: { in: RequestMigrations.supported_versions }, optional: true
          param :protected, type: :boolean, optional: true
        end
      end
    }
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

      account.destroy
    end

    private

    attr_reader :account

    def set_account
      @account = current_account

      Current.resource = account
    end
  end
end

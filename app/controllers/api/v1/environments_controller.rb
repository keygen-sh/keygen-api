# frozen_string_literal: true

module Api::V1
  class EnvironmentsController < Api::V1::BaseController
    before_action :require_ee!
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_environment, only: %i[show update destroy]

    def index
      environments = apply_pagination(authorized_scope(apply_scopes(current_account.environments)))
      authorize! environments

      render jsonapi: environments
    end

    def show
      authorize! environment

      render jsonapi: environment
    end

    typed_params {
      format :jsonapi

      param :data, type: :hash do
        param :type, type: :string, inclusion: { in: %w[environment environments] }
        param :attributes, type: :hash do
          param :name, type: :string
          param :code, type: :string
          param :isolation_strategy, type: :string, optional: true
        end
        param :relationships, type: :hash, optional: true do
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
    }
    def create
      environment = current_account.environments.new(environment_params)
      authorize! environment

      if environment.save
        BroadcastEventService.call(
          event: 'environment.created',
          account: current_account,
          resource: environment,
        )

        render jsonapi: environment, status: :created, location: v1_account_environment_url(environment.account, environment)
      else
        render_unprocessable_resource environment
      end
    end

    typed_params {
      format :jsonapi

      param :data, type: :hash do
        param :type, type: :string, inclusion: { in: %w[environment environments] }
        param :id, type: :uuid, optional: true, noop: true
        param :attributes, type: :hash do
          param :name, type: :string, optional: true
          param :code, type: :string, optional: true
        end
      end
    }
    def update
      authorize! environment

      if environment.update(environment_params)
        BroadcastEventService.call(
          event: 'environment.updated',
          account: current_account,
          resource: environment,
        )

        render jsonapi: environment
      else
        render_unprocessable_resource environment
      end
    end

    def destroy
      authorize! environment

      BroadcastEventService.call(
        event: 'environment.deleted',
        account: current_account,
        resource: environment,
      )

      environment.destroy_async
    end

    private

    attr_reader :environment

    def set_environment
      scoped_environments = authorized_scope(current_account.environments)

      @environment = FindByAliasService.call(scoped_environments, id: params[:id], aliases: :code)

      Current.resource = environment
    end

    def require_ee!
      super(entitlements: %i[environments])
    end
  end
end

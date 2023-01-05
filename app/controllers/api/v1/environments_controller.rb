# frozen_string_literal: true

module Api::V1
  class EnvironmentsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :scope_to_current_environment!
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
        param :id, type: :string, optional: true, noop: true
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

      environment.destroy
    end

    private

    attr_reader :environment

    def set_environment
      scoped_environments = authorized_scope(current_account.environments)

      @environment = FindByAliasService.call(scoped_environments, id: params[:id], aliases: :code)

      Current.resource = environment
    end
  end
end

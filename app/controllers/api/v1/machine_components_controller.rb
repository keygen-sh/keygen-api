# frozen_string_literal: true

module Api::V1
  class MachineComponentsController < Api::V1::BaseController
    has_scope(:product) { |c, s, v| s.for_product(v) }
    has_scope(:machine) { |c, s, v| s.for_machine(v) }
    has_scope(:license) { |c, s, v| s.for_license(v) }
    has_scope(:user) { |c, s, v| s.for_user(v) }
    has_scope(:status) { |c, s, v| s.with_status(v) }

    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_machine_component, only: %i[show update destroy]

    def index
      machine_components = apply_pagination(authorized_scope(apply_scopes(current_account.machine_components)).preload(:machine, :license, :policy, :product, :group, :user))
      authorize! machine_components

      render jsonapi: machine_components
    end

    def show
      authorize! machine_component

      render jsonapi: machine_component
    end

    typed_params {
      format :jsonapi

      param :data, type: :hash do
        param :type, type: :string, inclusion: { in: %w[component components] }
        param :attributes, type: :hash do
          param :fingerprint, type: :string
          param :name, type: :string
          param :metadata, type: :metadata, allow_blank: true, optional: true
        end
        param :relationships, type: :hash do
          param :machine, type: :hash do
            param :data, type: :hash do
              param :type, type: :string, inclusion: { in: %w[machine machines] }
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
      machine_component = current_account.machine_components.new(machine_component_params)
      authorize! machine_component

      if machine_component.save
        BroadcastEventService.call(
          event: 'component.created',
          account: current_account,
          resource: machine_component,
        )

        render jsonapi: machine_component, status: :created, location: v1_account_machine_component_url(machine_component.account, machine_component)
      else
        render_unprocessable_resource(machine_component)
      end
    end

    typed_params {
      format :jsonapi

      param :data, type: :hash do
        param :type, type: :string, inclusion: { in: %w[component components] }
        param :id, type: :string, optional: true, noop: true
        param :attributes, type: :hash do
          param :name, type: :string, optional: true
          param :metadata, type: :metadata, allow_blank: true, optional: true, if: -> { current_bearer&.has_role?(:admin, :developer, :sales_agent, :support_agent, :product, :environment) }
        end
      end
    }
    def update
      authorize! machine_component

      if machine_component.update(machine_component_params)
        BroadcastEventService.call(
          event: 'component.updated',
          account: current_account,
          resource: machine_component,
        )

        render jsonapi: machine_component
      else
        render_unprocessable_resource(machine_component)
      end
    end

    def destroy
      authorize! machine_component

      BroadcastEventService.call(
        event: 'component.deleted',
        account: current_account,
        resource: machine_component,
      )

      machine_component.destroy
    end

    private

    attr_reader :machine_component

    def set_machine_component
      scoped_components = authorized_scope(current_account.machine_components)

      @machine_component = scoped_components.find(params[:id])

      Current.resource = machine_component
    end
  end
end

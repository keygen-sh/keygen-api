# frozen_string_literal: true

module Api::V1::Groups::Relationships
  class MachinesController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_group

    authorize :group

    def index
      machines = apply_pagination(authorized_scope(apply_scopes(group.machines), with: Groups::MachinePolicy).preload(:product, :policy, :license, :owner))
      authorize! machines,
        with: Groups::MachinePolicy

      render jsonapi: machines
    end

    def show
      machine = FindByAliasService.call(group.machines, id: params[:id], aliases: :fingerprint)
      authorize! machine,
        with: Groups::MachinePolicy

      render jsonapi: machine
    end

    private

    attr_reader :group

    def set_group
      scoped_groups = authorized_scope(current_account.groups)

      @group = scoped_groups.find(params[:group_id])

      Current.resource = group
    end
  end
end

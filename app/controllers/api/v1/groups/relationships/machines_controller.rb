# frozen_string_literal: true

module Api::V1::Groups::Relationships
  class MachinesController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_group

    def index
      machines = policy_scope apply_scopes(group.machines)
      authorize machines

      render jsonapi: machines
    end

    def show
      machine = FindByAliasService.call(scope: group.machines, identifier: params[:id], aliases: :fingerprint)
      authorize machine

      render jsonapi: machine
    end

    private

    attr_reader :group

    def set_group
      @group = current_account.groups.find(params[:group_id])
      authorize group, :show?

      Current.resource = group
    end
  end
end

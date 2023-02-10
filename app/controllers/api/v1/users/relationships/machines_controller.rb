# frozen_string_literal: true

module Api::V1::Users::Relationships
  class MachinesController < Api::V1::BaseController
    has_scope(:fingerprint) { |c, s, v| s.with_fingerprint(v) }
    has_scope(:product) { |c, s, v| s.for_product(v) }
    has_scope(:license) { |c, s, v| s.for_license(v) }

    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_user

    authorize :user

    def index
      machines = apply_pagination(authorized_scope(apply_scopes(user.machines)).preload(:product, :policy, :license, :user))
      authorize! machines,
        with: Users::MachinePolicy

      render jsonapi: machines
    end

    def show
      machine = FindByAliasService.call(user.machines, id: params[:id], aliases: :fingerprint)
      authorize! machine,
        with: Users::MachinePolicy

      render jsonapi: machine
    end

    private

    attr_reader :user

    def set_user
      scoped_users = authorized_scope(current_account.users)

      @user = FindByAliasService.call(scoped_users, id: params[:user_id], aliases: :email)

      Current.resource = user
    end
  end
end

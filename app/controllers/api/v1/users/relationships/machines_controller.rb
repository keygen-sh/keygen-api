# frozen_string_literal: true

module Api::V1::Users::Relationships
  class MachinesController < Api::V1::BaseController
    has_scope :fingerprint
    has_scope :product
    has_scope :license

    prepend_before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_user

    # GET /users/1/machines
    def index
      @machines = policy_scope apply_scopes(@user.machines.preload(:product, :policy))
      authorize @machines

      render jsonapi: @machines
    end

    # GET /users/1/machines/1
    def show
      @machine = FindByAliasService.new(@user.machines, params[:id], aliases: :fingerprint).call
      authorize @machine

      render jsonapi: @machine
    end

    private

    def set_user
      @user = FindByAliasService.new(current_account.users, params[:user_id], aliases: :email).call
      authorize @user, :show?

      Keygen::Store::Request.store[:current_resource] = @user
    end
  end
end

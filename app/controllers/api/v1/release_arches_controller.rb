# frozen_string_literal: true

module Api::V1
  class ReleaseArchesController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token
    before_action :set_arch, only: %i[show]

    def index
      arches = apply_pagination(authorized_scope(apply_scopes(current_account.release_arches.with_releases)))
      authorize! arches

      render jsonapi: arches
    end

    def show
      authorize! arch

      render jsonapi: arch
    end

    private

    attr_reader :arch

    def set_arch
      scoped_arches = authorized_scope(current_account.release_arches)

      @arch = scoped_arches.find(params[:id])

      Current.resource = arch
    end
  end
end

# frozen_string_literal: true

module Api::V1
  class ReleaseEnginesController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token
    before_action :set_engine, only: %i[show]

    def index
      engines = apply_pagination(authorized_scope(apply_scopes(current_account.release_engines.with_packages)))
      authorize! engines

      render jsonapi: engines
    end

    def show
      authorize! engine

      render jsonapi: engine
    end

    private

    attr_reader :engine

    def set_engine
      scoped_engines = authorized_scope(current_account.release_engines)

      @engine = Current.resource = FindByAliasService.call(
        scoped_engines,
        id: params[:id],
        aliases: :key,
      )
    end
  end
end

# frozen_string_literal: true

module Api::V1::Licenses::Relationships
  class MachinesController < Api::V1::BaseController
    has_scope(:fingerprint) { |c, s, v| s.with_fingerprint(v) }
    has_scope(:product) { |c, s, v| s.for_product(v) }
    has_scope(:user) { |c, s, v| s.for_user(v) }

    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_license

    def index
      machines = apply_pagination(policy_scope(apply_scopes(license.machines)).preload(:product, :policy))
      authorize! license, machines

      render jsonapi: machines
    end

    def show
      machine = FindByAliasService.call(scope: license.machines, identifier: params[:id], aliases: :fingerprint)
      authorize! license, machine

      render jsonapi: machine
    end

    private

    attr_reader :license

    def set_license
      scoped_licenses = policy_scope(current_account.licenses)

      @license = FindByAliasService.call(scope: scoped_licenses, identifier: params[:license_id], aliases: :key)

      Current.resource = license
    end
  end
end

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

    authorize :license

    def index
      machines = apply_pagination(authorized_scope(apply_scopes(license.machines)).preload(:product, :policy, :owner, license: %i[policy owner]))
      authorize! machines,
        with: Licenses::MachinePolicy

      render jsonapi: machines
    end

    def show
      machine = FindByAliasService.call(license.machines, id: params[:id], aliases: :fingerprint)
      authorize! machine,
        with: Licenses::MachinePolicy

      render jsonapi: machine
    end

    private

    attr_reader :license

    def set_license
      scoped_licenses = authorized_scope(current_account.licenses)

      @license = FindByAliasService.call(scoped_licenses, id: params[:license_id], aliases: :key)

      Current.resource = license
    end
  end
end

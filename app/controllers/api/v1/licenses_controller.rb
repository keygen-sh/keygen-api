# frozen_string_literal: true

module Api::V1
  class LicensesController < Api::V1::BaseController
    has_scope(:metadata, type: :hash, only: :index) { |c, s, v| s.with_metadata(v) }
    has_scope(:product) { |c, s, v| s.for_product(v) }
    has_scope(:policy) { |c, s, v| s.for_policy(v) }
    has_scope(:owner) { |c, s, v| s.for_owner(v) }
    has_scope(:user) { |c, s, v| s.for_user(v) }
    has_scope(:machine) { |c, s, v| s.for_machine(v) }
    has_scope(:group) { |c, s, v| s.for_group(v) }
    has_scope(:status) { |c, s, v| s.with_status(v) }
    has_scope(:expires, type: :hash, only: :index) { |c, s, v|
      s.expires(**v.symbolize_keys.slice(:within, :in, :before, :after))
    }
    has_scope(:activity, type: :hash, only: :index) { |c, s, v|
      s.activity(**v.symbolize_keys.slice(:inside, :outside, :before, :after))
    }
    has_scope :suspended
    has_scope :expiring
    has_scope :expired
    has_scope :unassigned
    has_scope :assigned
    has_scope :activated
    has_scope(:activations, type: :hash, only: :index) { |c, s, v|
      s.activations(**v.symbolize_keys.slice(:eq, :gt, :gte, :lt, :lte))
    }

    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_license, only: %i[show update destroy]

    def index
      licenses = apply_pagination(authorized_scope(apply_scopes(current_account.licenses)).preload(:role, :product, :policy, owner: %i[role]))
      authorize! licenses

      render jsonapi: licenses
    end

    def show
      authorize! license

      render jsonapi: license
    end

    typed_params {
      format :jsonapi

      param :data, type: :hash do
        param :type, type: :string, inclusion: { in: %w[license licenses] }
        param :id, type: :uuid, optional: true, if: -> { current_bearer&.has_role?(:admin, :developer, :sales_agent, :product, :environment) }
        param :attributes, type: :hash, optional: true do
          param :name, type: :string, allow_blank: true, allow_nil: true, optional: true
          param :key, type: :string, optional: true
          with if: -> { current_bearer&.has_role?(:admin, :developer, :sales_agent, :product, :environment) } do
            param :protected, type: :boolean, optional: true
            param :expiry, type: :time, optional: true, coerce: true, allow_nil: true
            param :suspended, type: :boolean, optional: true
            param :max_machines, type: :integer, allow_nil: true, optional: true
            param :max_cores, type: :integer, allow_nil: true, optional: true
            param :max_uses, type: :integer, allow_nil: true, optional: true
            param :max_processes, type: :integer, allow_nil: true, optional: true
            param :max_users, type: :integer, allow_nil: true, optional: true
          end
          param :metadata, type: :metadata, allow_blank: true, optional: true

          Keygen.ee do |license|
            next unless
              license.entitled?(:permissions)

            param :permissions, type: :array, optional: true, if: -> { current_bearer&.has_role?(:admin, :developer, :sales_agent, :product, :environment) } do
              items type: :string
            end
          end
        end
        param :relationships, type: :hash do
          param :policy, type: :hash do
            param :data, type: :hash do
              param :type, type: :string, inclusion: { in: %w[policy policies] }
              param :id, type: :uuid
            end
          end
          param :owner, type: :hash, alias: :user, optional: true do
            param :data, type: :hash, allow_nil: true do
              param :type, type: :string, inclusion: { in: %w[user users] }
              param :id, type: :uuid
            end
          end
          param :group, type: :hash, optional: true, if: -> { current_bearer&.has_role?(:admin, :developer, :sales_agent, :support_agent, :product, :environment) } do
            param :data, type: :hash, allow_nil: true do
              param :type, type: :string, inclusion: { in: %w[group groups] }
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
      license = current_account.licenses.new(**license_params)
      authorize! license

      if license.save
        BroadcastEventService.call(
          event: 'license.created',
          account: current_account,
          resource: license,
        )

        render jsonapi: license, status: :created, location: v1_account_license_url(license.account_id, license)
      else
        render_unprocessable_resource license
      end
    end

    typed_params {
      format :jsonapi

      param :data, type: :hash do
        param :type, type: :string, inclusion: { in: %w[license licenses] }
        param :id, type: :string, optional: true, noop: true
        param :attributes, type: :hash do
          param :name, type: :string, allow_blank: true, allow_nil: true, optional: true
          with if: -> { current_bearer&.has_role?(:admin, :developer, :sales_agent, :support_agent, :product, :environment) } do
            param :expiry, type: :time, optional: true, coerce: true, allow_nil: true
            param :protected, type: :boolean, optional: true
            param :suspended, type: :boolean, optional: true
            param :max_machines, type: :integer, allow_nil: true, optional: true
            param :max_cores, type: :integer, allow_nil: true, optional: true
            param :max_uses, type: :integer, allow_nil: true, optional: true
            param :max_processes, type: :integer, allow_nil: true, optional: true
            param :max_users, type: :integer, allow_nil: true, optional: true
            param :metadata, type: :metadata, allow_blank: true, optional: true
          end

          Keygen.ee do |license|
            next unless
              license.entitled?(:permissions)

            param :permissions, type: :array, optional: true, if: -> { current_bearer&.has_role?(:admin, :developer, :sales_agent, :product, :environment) } do
              items type: :string
            end
          end
        end
      end
    }
    def update
      authorize! license

      if license.update(license_params)
        BroadcastEventService.call(
          event: 'license.updated',
          account: current_account,
          resource: license,
        )

        render jsonapi: license
      else
        render_unprocessable_resource license
      end
    end

    def destroy
      authorize! license

      BroadcastEventService.call(
        event: 'license.deleted',
        account: current_account,
        resource: license,
      )

      license.destroy
    end

    private

    attr_reader :license

    def set_license
      scoped_licenses = authorized_scope(current_account.licenses)

      @license = FindByAliasService.call(scoped_licenses, id: params[:id], aliases: :key)

      Current.resource = license
    end
  end
end

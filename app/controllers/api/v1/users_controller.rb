# frozen_string_literal: true

module Api::V1
  class UsersController < Api::V1::BaseController
    has_scope(:metadata, type: :hash, only: :index) { |c, s, v| s.with_metadata(v) }
    has_scope(:roles, type: :array, default: [:user]) { |c, s, v| s.with_roles(v) }
    has_scope(:product) { |c, s, v| s.for_product(v) }
    has_scope(:group) { |c, s, v| s.for_group(v) }
    has_scope(:status) { |c, s, v| s.with_status(v) }

    # NOTE(ezekg) This has an :active alias for backwards compatibility
    has_scope(:assigned, :boolean) { |c, s, v| s.assigned(v) }
    has_scope(:active, :boolean) { |c, s, v| s.assigned(v) }

    before_action :scope_to_current_account!
    before_action :require_active_subscription!, only: %i[index create destroy]
    before_action :authenticate_with_token!, only: %i[index show update destroy]
    before_action :authenticate_with_token, only: %i[create]
    before_action :set_user, only: %i[show update destroy]

    def index
      # We're applying scopes and preloading after the policy scope because
      # our policy scope may include a UNION, and scopes/preloading need to
      # be applied after the UNION query has been performed.
      users = apply_pagination(authorized_scope(apply_scopes(current_account.users)).preload(:role))
      authorize! users

      render jsonapi: users
    end

    def show
      authorize! user

      render jsonapi: user
    end

    typed_params {
      format :jsonapi

      param :data, type: :hash do
        param :type, type: :string, inclusion: { in: %w[user users] }
        param :attributes, type: :hash do
          param :first_name, type: :string, allow_blank: true, optional: true
          param :last_name, type: :string, allow_blank: true, optional: true
          param :email, type: :string
          param :password, type: :string, allow_nil: true, optional: true
          param :metadata, type: :metadata, allow_blank: true, optional: true
          param :role, type: :string, inclusion: { in: %w[user admin developer sales-agent support-agent] }, optional: true,
            if: -> { current_bearer&.has_role?(:admin) },
            transform: -> (k, v) {
              [:role_attributes, { name: v.underscore }]
            }

          Keygen.ee do |license|
            next unless
              license.entitled?(:permissions)

            param :permissions, type: :array, optional: true, if: -> { current_account.ent? && current_bearer&.has_role?(:admin, :product, :environment) } do
              items type: :string
            end
          end
        end
        param :relationships, type: :hash, optional: true do
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
      user = current_account.users.new user_params
      authorize! user

      if user.save
        BroadcastEventService.call(
          event: 'user.created',
          account: current_account,
          resource: user,
        )

        render jsonapi: user, status: :created, location: v1_account_user_url(user.account, user)
      else
        render_unprocessable_resource user
      end
    end

    typed_params {
      format :jsonapi

      param :data, type: :hash do
        param :type, type: :string, inclusion: { in: %w[user users] }
        param :id, type: :uuid, optional: true, noop: true
        param :attributes, type: :hash, optional: true do
          param :first_name, type: :string, allow_blank: true, allow_nil: true, optional: true
          param :last_name, type: :string, allow_blank: true, allow_nil: true, optional: true
          param :email, type: :string, optional: true
          param :password, type: :string, allow_nil: true, optional: true, if: -> { current_bearer&.has_role?(:admin, :product, :environment) }
          param :metadata, type: :metadata, allow_blank: true, optional: true, if: -> { current_bearer&.has_role?(:admin, :developer, :sales_agent, :product, :environment) }
          param :role, type: :string, inclusion: { in: %w[user admin developer sales-agent support-agent] }, optional: true,
            if: -> { current_bearer&.has_role?(:admin) },
            transform: -> (k, v) {
              [:role_attributes, { name: v.underscore }]
            }

          Keygen.ee do |license|
            next unless
              license.entitled?(:permissions)

            param :permissions, type: :array, optional: true, if: -> { current_account.ent? && current_bearer&.has_role?(:admin, :product, :environment) } do
              items type: :string
            end
          end
        end
      end
    }
    def update
      # NOTE(ezekg) Wrapping in a transaction to cover any possible database side-effects
      #             of the attrs assignment, e.g. setting the IDs of an association.
      user.transaction do
        user.assign_attributes(user_params)

        # NOTE(ezekg) We're authorizing after assigning attrs to catch any unpermitted
        #             role changes, i.e. privilege escalation.
        authorize! user

        user.save!
      end

      BroadcastEventService.call(
        event: 'user.updated',
        account: current_account,
        resource: user,
      )

      render jsonapi: user
    end

    def destroy
      authorize! user

      # NOTE(ezekg) Using a condition here because destroy async may return
      #             false if the user an admin and a minimum has been hit.
      if user.destroy_async
        BroadcastEventService.call(
          event: 'user.deleted',
          account: current_account,
          resource: user,
        )

        head :no_content
      else
        render_unprocessable_resource user
      end
    end

    private

    attr_reader :user

    def set_user
      scoped_users = authorized_scope(current_account.users)

      @user = FindByAliasService.call(scoped_users, id: params[:id].downcase, aliases: :email)

      Current.resource = user
    end
  end
end

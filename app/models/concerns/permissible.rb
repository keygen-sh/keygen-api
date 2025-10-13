# frozen_string_literal: true

module Permissible
  extend ActiveSupport::Concern

  included do
    include Keygen::EE::ProtectedMethods[:permissions=, entitlements: %i[permissions]]

    ##
    # with_permissions returns a scope of models with a given permission set.
    scope :with_permissions, -> *identifiers {
      identifiers = identifiers.flatten
                               .compact

      joins(role_permissions: %i[permission])
        .where(permissions: { action: identifiers })
        .or(
          joins(role_permissions: %i[permission]).where(permissions: { id: identifiers })
        )
        .group(:id)
        .having(
          'COUNT(DISTINCT permissions.id) = ?',
          identifiers.size,
        )
    }

    ##
    # permissions= assigns a set of permissions to the role, either by action or permission ID.
    def permissions=(*identifiers)
      return if
        identifiers == [nil]

      identifiers = identifiers.flatten
                               .compact

      permission_ids =
        Permission.where(action: identifiers)
                  .or(
                    Permission.where(id: identifiers)
                  )
                  .pluck(:id)
                  .uniq

      # Invalid permissions would be ignored by default, but that doesn't
      # really provide a nice DX. We'll error instead of ignoring.
      if permission_ids.size != identifiers.size
        errors.add :permissions, :not_allowed, message: 'unsupported permissions'

        raise ActiveRecord::RecordInvalid, self
      end

      assign_attributes(
        role_attributes: { permissions: permission_ids },
      )
    end

    ##
    # can? returns true if the user does have all provided permissions.
    def can?(*actions)
      expected = actions.flatten.uniq
      actual   = permissions.where(action: [*expected, Permission::WILDCARD_PERMISSION])
                            .actions
                            .uniq

      if actual.include?(Permission::WILDCARD_PERMISSION)
        (allowed_permissions & expected).size == expected.size
      else
        actual.size == expected.size
      end
    end
    alias_method :permissions?,     :can?
    alias_method :has_permissions?, :can?

    ##
    # cannot? returns true if the user does not have all provided permissions.
    def cannot?(...) = !can?(...)

    ##
    # root? returns true if the role has all permissions, or if the role is an
    # admin with wildcard permissions.
    def root?
      return false unless
        admin?

      return permissions?(*Permission::ALL_PERMISSIONS) unless
        role_permissions_attributes_assigned?

      permission_ids = role_permissions_attributes.collect { it[:permission_id] }
      permissions    = Permission.where(id: permission_ids)
                                 .actions
                                 .uniq

      return true if
        permissions.include?(Permission::WILDCARD_PERMISSION)

      (permissions & Permission::ALL_PERMISSIONS).size == Permission::ALL_PERMISSIONS.size
    end
    alias_method :all_permissions?, :root?

    ##
    # default_permissions? returns true if the model has the default permission set.
    #
    # Use :except to exclude an array of permissions, e.g. in case we're querying
    # the old default permissions after adding new permissions.
    #
    # Use :with to provide a set of preloaded permissions.
    def default_permissions?(except: [], with: permissions.actions)
      a = default_permissions - except
      b = with

      a.size == b.size && (a & b).size == a.size
    end

    def wildcard_permissions? = permissions?(Permission::WILDCARD_PERMISSION)
  end

  class_methods do
    ##
    # has_permissions defines a model's permissions and their default permission set.
    def has_permissions(permissions, default: nil)
      resolver = -> ctx, opts {
        case opts
        when Proc
          if opts.arity > 0
            [*instance_exec(ctx, &opts)]
          else
            [*instance_exec(&opts)]
          end
        when Array
          [*opts]
        else
          []
        end
      }

      # NOTE(ezekg) Using define_singleton_method and define_method here so that we
      #             can access variables outside of the default def scope gate,
      #             like the permissions arg and :default kwarg.
      module_eval do
        define_singleton_method :allowed_permissions do
          perms = resolver.call(nil, permissions)

          # Wildcards are always allowed.
          perms << Permission::WILDCARD_PERMISSION

          perms.freeze
        end

        define_singleton_method :default_permissions do
          perms = resolver.call(nil, default)

          # When no defaults are provided, default to allowed minus wildcard.
          next allowed_permissions.reject { it == Permission::WILDCARD_PERMISSION }
                                  .freeze if
            perms.empty?

          perms.freeze
        end

        define_method :allowed_permissions do
          perms = resolver.call(self, permissions)

          # Wildcards are always allowed.
          perms << Permission::WILDCARD_PERMISSION

          perms.freeze
        end

        define_method :default_permissions do
          perms = resolver.call(self, default)

          # When no defaults are provided, default to allowed minus wildcard.
          next allowed_permissions.reject { it == Permission::WILDCARD_PERMISSION }
                                  .freeze if
            perms.empty?

          perms.freeze
        end
      end

      module_eval <<~RUBY, __FILE__, __LINE__ + 1
        def self.allowed_permission_ids = Permission.where(action: allowed_permissions).ids
        def self.default_permission_ids = Permission.where(action: default_permissions).ids

        def allowed_permission_ids = Permission.where(action: allowed_permissions).ids
        def default_permission_ids = Permission.where(action: default_permissions).ids
      RUBY
    end
  end
end

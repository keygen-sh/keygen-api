# frozen_string_literal: true

module Permissible
  extend ActiveSupport::Concern

  included do
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

    def can?(*actions)
      expected = actions.flatten
      actual   = permissions.where(action: [*expected, Permission::WILDCARD_PERMISSION])
                            .pluck(:action)

      return true if
        actual.include?(Permission::WILDCARD_PERMISSION)

      actual.size == expected.size
    end
    alias_method :has_permissions?, :can?

    def cannot?(...) = !can?(...)
  end

  class_methods do
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
          perms = resolver.call(self, permissions)

          # Wildcards are always allowed.
          perms << Permission::WILDCARD_PERMISSION

          perms.freeze
        end

        define_method :allowed_permissions do
          perms = resolver.call(self, permissions)

          # Wildcards are always allowed.
          perms << Permission::WILDCARD_PERMISSION

          perms.freeze
        end

        define_singleton_method :default_permissions do
          perms = resolver.call(self, default)

          # When no defaults are provided, default to allowed.
          next allowed_permissions if
            perms.empty?

          perms.freeze
        end

        define_method :default_permissions do
          perms = resolver.call(self, default)

          # When no defaults are provided, default to allowed.
          next allowed_permissions if
            perms.empty?

          perms.freeze
        end
      end

      module_eval <<~RUBY, __FILE__, __LINE__ + 1
        def self.allowed_permission_ids = Permission.where(action: allowed_permissions).pluck(:id)
        def self.default_permission_ids = Permission.where(action: default_permissions).pluck(:id)

        def allowed_permission_ids = Permission.where(action: allowed_permissions).pluck(:id)
        def default_permission_ids = Permission.where(action: default_permissions).pluck(:id)
      RUBY
    end
  end
end

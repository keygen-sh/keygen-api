# frozen_string_literal: true

module Permissible
  extend ActiveSupport::Concern

  included do
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

      case
      # Invalid permissions would be ignored by default, but that doesn't
      # really provide a nice DX. We'll error instead of ignoring.
      when permission_ids.size != identifiers.size
        errors.add :permissions, :not_allowed, message: 'unsupported permissions'

        return
      # Assert the model cannot exceed their allowed permission set
      when (permission_ids - allowed_permission_ids).any?
        errors.add :permissions, :not_allowed, message: 'invalid permissions'

        return
      end

      assign_attributes(
        role_attributes: { permissions: permission_ids },
      )
    end

    def can?(*actions)
      permissions.exists?(
        action: actions.flatten << Permission::WILDCARD_PERMISSION,
      )
    end

    def cannot?(...) = !can?(...)
  end

  class_methods do
    def has_permissions(permissions, default: nil)
      # NOTE(ezekg) Using define_singleton_method and define_method here so that we
      #             can access variables outside of the default def scope gate.
      module_eval do
        define_singleton_method :allowed_permissions do
          [*permissions, Permission::WILDCARD_PERMISSION].freeze
        end

        define_singleton_method :default_permissions do
          case default
          when Proc
            if default.arity > 0
              instance_exec(self, &default)
            else
              instance_exec(&default)
            end
          when Array
            [*default]
          else
            [*permissions]
          end.freeze
        end

        define_method :allowed_permissions do
          [*permissions, Permission::WILDCARD_PERMISSION].freeze
        end

        define_method :default_permissions do
          case default
          when Proc
            if default.arity > 0
              instance_exec(self, &default)
            else
              instance_exec(&default)
            end
          when Array
            [*default]
          else
            [*permissions]
          end.freeze
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

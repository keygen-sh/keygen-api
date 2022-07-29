# frozen_string_literal: true

module Roleable
  extend ActiveSupport::Concern

  included do
    def permissions=(*identifiers)
      identifiers = identifiers.flatten
                               .compact

      permission_ids =
        Permission.where(action: identifiers)
                  .or(
                    Permission.where(id: identifiers)
                  )
                  .pluck(:id)

      # Invalid permissions would be ignored by default, but that doesn't
      # really provide a nice DX. We'll error instead of ignoring.
      if permission_ids.size != identifiers.size
        errors.add :permissions, :not_allowed, message: 'unsupported permissions'

        raise ActiveRecord::RecordInvalid, self
      end

      if new_record?
        role_permissions_attributes = permission_ids.map {{ permission_id: _1 }}

        assign_attributes(role_attributes: { role_permissions_attributes: })
      else
        role.permissions = permission_ids
      end
    end

    def grant_role!(name)
      if persisted?
        role.update!(name:)
      else
        assign_attributes(role_attributes: { name: })
      end
    end

    def revoke_role!(name)
      raise RoleInvalid, 'role is missing' unless
        role.present?

      raise RoleInvalid, 'role is invalid' unless
        name.to_s == role.name.to_s

      role.destroy!
    end

    def has_role?(*names)
      return false if
        role.nil?

      names.any? { _1.to_s == role.name.to_s }
    end
    alias_method :has_roles?, :has_role?

    def was_role?(name)
      return false if
        role.nil? || !role.name_changed?

      name.to_s == role.name_was.to_s
    end

    def role?    = role.present? && role.name?
    def user?    = role? && role.user?
    def admin?   = role? && role.admin?
    def product? = role? && role.product?
    def license? = role? && role.license?
  end

  class_methods do
    def has_default_role(name)
      define_roleable_association_and_delgate

      after_initialize -> { grant_role!(name) },
        unless: -> { persisted? || role? }

      define_roleable_dirty_tracker
    end

    def has_role(name)
      define_roleable_association_and_delgate

      after_initialize -> { grant_role!(name) },
        unless: :persisted?

      define_roleable_dirty_tracker
    end

    private

    def define_roleable_association_and_delgate
      has_one :role,
        inverse_of: :resource,
        dependent: :destroy,
        as: :resource

      accepts_nested_attributes_for :role,
        update_only: true

      delegate :can?, :cannot?, :permissions,
        allow_nil: true,
        to: :role
    end

    def define_roleable_dirty_tracker
      # FIXME(ezekg) Can't find a way to determine whether or not nested attributes
      #              have been provided. This adds a flag we can check. Will be nil
      #              when nested attributes have not been provided.
      module_eval <<-RUBY, __FILE__, __LINE__ + 1
        alias :_role_attributes= :role_attributes=

        def role_attributes_changed? = instance_variable_defined?(:@role_attributes_before_type_cast)
        def role_attributes=(attributes)
          @role_attributes_before_type_cast = attributes.dup

          self._role_attributes = attributes
        end
      RUBY
    end
  end

  private

  class RoleInvalid < StandardError; end
end

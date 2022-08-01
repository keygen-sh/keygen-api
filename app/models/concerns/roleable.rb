# frozen_string_literal: true

module Roleable
  extend ActiveSupport::Concern

  included do
    def grant_role!(name)
      errors.add :role, :not_allowed, message: 'role already exists' if
        persisted?

      assign_attributes(role_attributes: { name: })
    end

    def replace_role!(name)
      errors.add :role, :not_allowed, message: 'role is missing' unless
        persisted?

      role.update!(name:)
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

      # Set default role for new objects unless already set
      after_initialize -> { grant_role!(name) },
        unless: -> { persisted? || role? }

      define_roleable_callbacks
    end

    def has_role(name)
      define_roleable_association_and_delgate

      # Set role for new objects
      after_initialize -> { grant_role!(name) },
        unless: :persisted?

      define_roleable_callbacks
    end

    private

    def define_roleable_association_and_delgate
      include Permissible
      include Dirtyable

      has_one :role,
        inverse_of: :resource,
        dependent: :destroy,
        as: :resource

      accepts_nested_attributes_for :role, update_only: true
      tracks_dirty_attributes_for :role

      delegate :permissions,
        allow_nil: true,
        to: :role
    end

    def define_roleable_callbacks
      # Set default permissions unless already set
      before_create -> { self.permissions = default_permissions },
        unless: -> { role&.role_permissions_attributes_changed? }

      # Reset permissions on role change
      before_update -> { self.permissions = default_permissions },
        if: -> { role&.changed? }
    end
  end

  private

  class RoleInvalid < StandardError; end
end

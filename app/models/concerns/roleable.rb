# frozen_string_literal: true

module Roleable
  extend ActiveSupport::Concern

  included do
    def grant_role!(name)
      errors.add :role, :not_allowed, message: 'role already exists' if
        persisted?

      assign_attributes(role_attributes: { name: })
    end

    def change_role!(name)
      errors.add :role, :not_allowed, message: 'role is missing' unless
        persisted?

      update!(role_attributes: { name: })
    end

    def revoke_role!(name)
      raise RoleInvalid, 'role is missing' unless
        role.present?

      raise RoleInvalid, 'role is invalid' unless
        name.to_s == role.name.to_s

      role.destroy!
    end

    def role_changed?
      return false if
        role.nil?

      role.name.to_s != role.name_was.to_s
    end

    def has_role?(*names)
      return false if
        role.nil?

      names.any? { _1.to_s == role.name.to_s }
    end
    alias_method :has_roles?, :has_role?

    def was_role?(name)
      return false if
        role.nil?

      name.to_s == role.name_was.to_s
    end

    def role?        = role.present? && role.name?
    def user?        = role? && role.user?
    def admin?       = role? && role.admin?
    def environment? = role? && role.environment?
    def product?     = role? && role.product?
    def license?     = role? && role.license?

    def changed_for_autosave?
      super || role_attributes_assigned?
    end
  end

  class_methods do
    def has_default_role(name)
      define_roleable_association_and_delgate

      # Set default role for new objects unless already set
      after_initialize -> { grant_role!(name) },
        unless: -> { persisted? || role? }
    end

    def has_role(name)
      define_roleable_association_and_delgate

      # Set role for new objects
      after_initialize -> { grant_role!(name) },
        unless: :persisted?
    end

    private

    def define_roleable_association_and_delgate
      include Permissible
      include Dirtyable

      has_one :role,
        inverse_of: :resource,
        dependent: :destroy_async,
        autosave: true,
        as: :resource

      has_many :role_permissions,
        through: :role

      accepts_nested_attributes_for :role, update_only: true
      tracks_nested_attributes_for :role

      validates :role,
        presence: { message: 'must exist' }

      delegate :permissions, :permission_ids, :role_permissions,
        :role_permissions_attributes_assigned?, :role_permissions_attributes,
        allow_nil: true,
        to: :role
    end
  end

  private

  class RoleInvalid < StandardError; end
end

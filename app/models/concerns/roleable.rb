# frozen_string_literal: true

module Roleable
  extend ActiveSupport::Concern

  included do
    delegate :can?,
      :permissions,
      to: :role

    def permissions=(*actions)
      ids = Permission.where(action: actions.flatten)
                      .pluck(:id)

      if new_record?
        role_permissions_attributes = ids.map {{ permission_id: _1 }}

        assign_attributes(role_attributes: { role_permissions_attributes: })
      else
        role.permissions = ids
      end
    end

    def grant_role!(name)
      if persisted?
        if role.nil?
          create_role!(name:)
        else
          role.update!(name:)
        end
      else
        assign_attributes(role_attributes: { name: })
      end
    end

    def revoke_role!(name)
      return false if
        role.nil? || name.to_s != role.name

      role.destroy
    end

    def has_role?(*names)
      return false if
        role.nil?

      names.any? { _1.to_s == role.name }
    end

    def was_role?(name)
      return false if
        role.nil? || !role.name_changed?

      name.to_s == role.name_was
    end

    def role?
      role.present?
    end
  end
end

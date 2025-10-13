# frozen_string_literal: true

module Users
  class LicensePolicy < ApplicationPolicy
    authorize :user

    def index?
      verify_permissions!('license.read')
      verify_environment!(
        strict: false,
      )

      case bearer
      in role: Role(:admin | :developer | :sales_agent | :support_agent | :read_only | :environment)
        allow!
      in role: Role(:product) if user.user?
        record.all? { it.product == bearer }
      in role: Role(:user) if user == bearer
        record.all? { it.owner == bearer || it.id.in?(bearer.license_ids) }
      else
        deny!
      end
    end

    def show?
      verify_permissions!('license.read')
      verify_environment!(
        strict: false,
      )

      case bearer
      in role: Role(:admin | :developer | :sales_agent | :support_agent | :read_only | :environment)
        allow!
      in role: Role(:product) if user.user?
        record.product == bearer
      in role: Role(:user) if user == bearer
        record.owner == bearer || bearer.licenses.exists?(record.id)
      else
        deny!
      end
    end
  end
end

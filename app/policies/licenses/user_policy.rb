# frozen_string_literal: true

module Licenses
  class UserPolicy < ApplicationPolicy
    authorize :license

    def index?
      verify_permissions!('user.read')
      verify_environment!(
        strict: false,
      )

      case bearer
      in role: Role(:admin | :developer | :sales_agent | :support_agent | :read_only | :environment)
        allow!
      in role: Role(:product) if license.product == bearer
        allow!
      in role: Role(:user) if license.owner == bearer || license.licensees.exists?(bearer.id)
        allow!
      in role: Role(:license) if license == bearer
        allow!
      else
        deny!
      end
    end

    def show?
      verify_permissions!('user.read')
      verify_environment!(
        strict: false,
      )

      case bearer
      in role: Role(:admin | :developer | :sales_agent | :support_agent | :read_only | :environment)
        allow!
      in role: Role(:product) if license.product == bearer
        allow!
      in role: Role(:user) if license.owner == bearer || license.licensees.exists?(bearer.id)
        allow!
      in role: Role(:license) if license == bearer
        allow!
      else
        deny!
      end
    end

    def attach?
      verify_permissions!('license.users.attach')
      verify_environment!(
        # NOTE(ezekg) This seems weird, but we want to allow attaching shared users
        #             to global licenses, but not vice-versa.
        strict: license.environment.nil?,
      )

      case bearer
      in role: Role(:admin | :developer | :sales_agent | :support_agent | :read_only | :environment)
        allow!
      in role: Role(:product) if license.product == bearer
        allow!
      in role: Role(:user) if license.owner == bearer
        allow!
      else
        deny!
      end
    end

    def detach?
      verify_permissions!('license.users.detach')
      verify_environment!(
        # NOTE(ezekg) ^^^ ditto above except for detaching.
        strict: license.environment.nil?,
      )

      case bearer
      in role: Role(:admin | :developer | :sales_agent | :support_agent | :read_only | :environment)
        allow!
      in role: Role(:product) if license.product == bearer
        allow!
      in role: Role(:user) if license.owner == bearer
        allow!
      else
        deny!
      end
    end
  end
end

# frozen_string_literal: true

module Machines
  class LicensePolicy < ApplicationPolicy
    authorize :machine

    def show?
      verify_permissions!('license.read')
      verify_environment!(
        strict: false,
      )

      case bearer
      in role: Role(:admin | :developer | :sales_agent | :support_agent | :read_only | :environment)
        allow!
      in role: Role(:product) if machine.product == bearer
        allow!
      in role: Role(:user) if machine.user == bearer
        allow!
      in role: Role(:license) if machine.license == bearer
        allow!
      else
        deny!
      end
    end
  end
end

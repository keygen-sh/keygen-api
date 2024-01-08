# frozen_string_literal: true

module MachineComponents
  class LicensePolicy < ApplicationPolicy
    authorize :machine_component

    def show?
      verify_permissions!('license.read')
      verify_environment!(
        strict: false,
      )

      case bearer
      in role: Role(:admin | :developer | :sales_agent | :support_agent | :read_only | :environment)
        allow!
      in role: Role(:product) if machine_component.product == bearer
        allow!
      in role: Role(:user) if machine_component.owner == bearer
        allow!
      in role: Role(:license) if machine_component.license == bearer
        allow!
      else
        deny!
      end
    end
  end
end

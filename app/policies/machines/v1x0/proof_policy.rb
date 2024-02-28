# frozen_string_literal: true

module Machines::V1x0
  class ProofPolicy < ApplicationPolicy
    authorize :machine

    def create?
      verify_permissions!('machine.proofs.generate')
      verify_environment!(
        strict: false,
      )

      case bearer
      in role: Role(:admin | :developer | :sales_agent | :environment)
        allow!
      in role: Role(:product) if machine.product == bearer
        allow!
      in role: Role(:user) if machine.owner == bearer || machine.license.owner == bearer
        !machine.license.protected?
      in role: Role(:license) if machine.license == bearer
        allow!
      else
        deny!
      end
    end
  end
end

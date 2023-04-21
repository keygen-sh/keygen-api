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
      in role: { name: 'admin' | 'developer' | 'sales_agent' | 'environment' }
        allow!
      in role: { name: 'product' } if machine.product == bearer
        allow!
      in role: { name: 'user' } if machine.user == bearer
        !machine.license.protected?
      in role: { name: 'license' } if machine.license == bearer
        allow!
      else
        deny!
      end
    end
  end
end

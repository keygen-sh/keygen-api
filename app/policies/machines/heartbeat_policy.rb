# frozen_string_literal: true

module Machines
  class HeartbeatPolicy < ApplicationPolicy
    authorize :machine

    def ping?
      verify_permissions!('machine.heartbeat.ping')
      verify_environment!(
        strict: false,
      )

      case bearer
      in role: Role(:admin | :developer | :environment)
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

    def reset?
      verify_permissions!('machine.heartbeat.reset')
      verify_environment!(
        strict: false,
      )

      case bearer
      in role: Role(:admin | :developer | :sales_agent | :environment)
        allow!
      in role: Role(:product) if machine.product == bearer
        allow!
      else
        deny!
      end
    end
  end
end

# frozen_string_literal: true

module MachineProcesses
  class HeartbeatPolicy < ApplicationPolicy
    authorize :machine_process

    def ping?
      verify_permissions!('process.heartbeat.ping')
      verify_environment!(
        strict: false,
      )

      case bearer
      in role: Role(:admin | :developer | :environment)
        allow!
      in role: Role(:product) if machine_process.product == bearer
        allow!
      in role: Role(:user) if machine_process.owner == bearer || machine_process.license.owner == bearer
        !machine_process.license.protected?
      in role: Role(:license) if machine_process.license == bearer
        allow!
      else
        deny!
      end
    end
  end
end

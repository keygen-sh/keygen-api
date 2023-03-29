# frozen_string_literal: true

module MachineProcesses
  class HeartbeatPolicy < ApplicationPolicy
    authorize :machine_process

    def ping?
      verify_permissions!('process.heartbeat.ping')
      verify_environment!

      case bearer
      in role: { name: 'admin' | 'developer' | 'environment' }
        allow!
      in role: { name: 'product' } if machine_process.product == bearer
        allow!
      in role: { name: 'user' } if machine_process.user == bearer
        !machine_process.license.protected?
      in role: { name: 'license' } if machine_process.license == bearer
        allow!
      else
        deny!
      end
    end
  end
end

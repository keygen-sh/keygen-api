# frozen_string_literal: true

module Machines
  class HeartbeatPolicy < ApplicationPolicy
    authorize :machine

    def ping?
      verify_permissions!('machine.heartbeat.ping')
      verify_environment!

      case bearer
      in role: { name: 'admin' | 'developer' }
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

    def reset?
      verify_permissions!('machine.heartbeat.reset')
      verify_environment!

      case bearer
      in role: { name: 'admin' | 'developer' | 'sales_agent' }
        allow!
      in role: { name: 'product' } if machine.product == bearer
        allow!
      else
        deny!
      end
    end
  end
end

# frozen_string_literal: true

module Licenses
  class UserPolicy < ApplicationPolicy
    authorize :license

    def show?
      verify_permissions!('user.read')

      case bearer
      in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
        allow!
      in role: { name: 'product' } if license.product == bearer
        allow!
      in role: { name: 'user' } if license.user == bearer
        allow!
      in role: { name: 'license' } if license == bearer
        allow!
      else
        deny!
      end
    end

    def update?
      verify_permissions!('license.user.update')
      verify_environment! do |environment|
        next if
          record.nil?

        deny! 'user environment is not compatible with the license environment' unless
          case
          when environment.nil?
            record.environment.nil?
          when environment.isolated?
            record.environment_id == environment.id
          when environment.shared?
            record.environment_id == environment.id || record.environment_id.nil?
          end
      end

      case bearer
      in role: { name: 'admin' | 'developer' | 'sales_agent' }
        allow!
      in role: { name: 'product' } if license.product == bearer
        allow!
      else
        deny!
      end
    end
  end
end

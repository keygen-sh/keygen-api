# frozen_string_literal: true

module Licenses
  class EnvironmentPolicy < ApplicationPolicy
    authorize :license

    def show?
      verify_permissions!('environment.read')

      case bearer
      in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
        allow!
      else
        deny!
      end
    end
  end
end

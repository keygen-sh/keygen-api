# frozen_string_literal: true

module Licenses
  class TokenPolicy < ApplicationPolicy
    authorize :license

    def index?
      verify_permissions!('token.read')
      verify_environment!(
        strict: false,
      )

      case bearer
      in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
        allow!
      in role: { name: 'product' } if license.product == bearer
        allow!
      else
        deny!
      end
    end

    def show?
      verify_permissions!('token.read')
      verify_environment!(
        strict: false,
      )

      case bearer
      in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
        allow!
      in role: { name: 'product' } if license.product == bearer
        allow!
      else
        deny!
      end
    end

    def create?
      verify_permissions!('license.tokens.generate')
      verify_environment!

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

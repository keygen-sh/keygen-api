# frozen_string_literal: true

module Environments
  class TokenPolicy < ApplicationPolicy
    def index?
      verify_permissions!('token.read')
      verify_environment!(
        strict: false,
      )

      case bearer
      in role: Role(:admin | :developer | :sales_agent | :support_agent | :read_only)
        allow!
      in role: Role(:environment) if environment == bearer
        record.all? { _1 in bearer_type: ^(Environment.name), bearer_id: ^(bearer.id) }
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
      in role: Role(:admin | :developer | :sales_agent | :support_agent | :read_only)
        allow!
      in role: Role(:environment) if environment == bearer && record.bearer == bearer
        allow!
      else
        deny!
      end
    end

    def create?
      verify_permissions!('environment.tokens.generate')
      verify_environment!

      case bearer
      in role: Role(:admin | :developer)
        allow!
      else
        deny!
      end
    end
  end
end

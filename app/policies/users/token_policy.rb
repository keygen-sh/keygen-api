# frozen_string_literal: true

module Users
  class TokenPolicy < ApplicationPolicy
    authorize :user

    def index?
      verify_permissions!('token.read')
      verify_environment!(
        strict: false,
      )

      case bearer
      in role: Role(:admin | :developer | :sales_agent | :support_agent | :read_only)
        allow!
      in role: Role(:product | :environment) if user.user?
        allow!
      in role: Role(:user) if user == bearer
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
      in role: Role(:admin | :developer | :sales_agent | :support_agent | :read_only)
        allow!
      in role: Role(:product | :environment) if user.user?
        allow!
      in role: Role(:user) if user == bearer
        allow!
      else
        deny!
      end
    end

    def create?
      verify_permissions!('user.tokens.generate')
      verify_environment!(
        # NOTE(ezekg) We're lax in the nil environment i.e. we need to be able to generate a token
        #             for a shared environment from the nil environment, but not vice-versa.
        strict: environment.present?,
      )

      case bearer
      in role: Role(:admin | :developer) if user == bearer || user.user?
        allow!
      in role: Role(:product | :environment) if user.user?
        allow!
      else
        deny!
      end
    end
  end
end

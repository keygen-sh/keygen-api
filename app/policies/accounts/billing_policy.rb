# frozen_string_literal: true

module Accounts
  class BillingPolicy < ApplicationPolicy
    def show?
      verify_permissions!('account.billing.read')
      verify_environment!(
        strict: false,
      )

      case bearer
      in role: Role(:admin)
        allow!
      else
        deny!
      end
    end

    def update?
      verify_permissions!('account.billing.update')
      verify_environment!

      case bearer
      in role: Role(:admin)
        allow!
      else
        deny!
      end
    end
  end
end

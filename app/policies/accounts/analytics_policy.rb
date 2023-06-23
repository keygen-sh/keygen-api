# frozen_string_literal: true

module Accounts
  class AnalyticsPolicy < ApplicationPolicy
    def show?
      verify_permissions!('account.analytics.read')
      verify_environment!

      case bearer
      in role: Role(:admin | :developer | :sales_agent | :support_agent | :read_only)
        allow!
      else
        deny!
      end
    end
  end
end

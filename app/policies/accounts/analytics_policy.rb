# frozen_string_literal: true

module Accounts
  class AnalyticsPolicy < ApplicationPolicy
    def show?
      verify_permissions!('account.analytics.read')

      case bearer
      in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
        allow!
      else
        deny!
      end
    end
  end
end

# frozen_string_literal: true

module Releases::V1x0
  class YankPolicy < ApplicationPolicy
    def yank?
      verify_permissions!('release.yank')
      verify_environment!

      case bearer
      in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
        allow!
      in role: { name: 'product' } if record.product == bearer
        allow!
      else
        deny!
      end
    end
  end
end

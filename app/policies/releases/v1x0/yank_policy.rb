# frozen_string_literal: true

module Releases::V1x0
  class YankPolicy < ApplicationPolicy
    def yank?
      verify_permissions!('release.yank')
      verify_environment!

      case bearer
      in role: Role(:admin | :developer | :sales_agent | :support_agent | :read_only | :environment)
        allow!
      in role: Role(:product) if record.product == bearer
        allow!
      else
        deny!
      end
    end
  end
end

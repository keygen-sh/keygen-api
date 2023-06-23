# frozen_string_literal: true

module Releases::V1x0
  class UploadPolicy < ApplicationPolicy
    def upload?
      verify_permissions!('release.upload')
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

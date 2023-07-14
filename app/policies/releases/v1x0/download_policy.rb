# frozen_string_literal: true

module Releases::V1x0
  class DownloadPolicy < ApplicationPolicy
    skip_pre_check :verify_authenticated!, only: %i[download? upgrade?]

    def download?
      verify_permissions!('release.download')
      verify_environment!(
        strict: false,
      )

      deny! if record.nil?

      case bearer
      in role: Role(:admin | :developer | :sales_agent | :support_agent | :read_only | :environment)
        allow!
      in role: Role(:product) if record.product == bearer
        allow!
      in role: Role(:user)
        allow? :show, record, skip_verify_permissions: true, with: ::ReleasePolicy
      in role: Role(:license)
        allow? :show, record, skip_verify_permissions: true, with: ::ReleasePolicy
      else
        record.open? && record.constraints.none?
      end
    end

    def upgrade?
      verify_permissions!('release.upgrade')
      verify_environment!(
        strict: false,
      )

      # Upgrading could result in a nil record, e.g. when no upgrade is available.
      allow! if record.nil?

      case bearer
      in role: Role(:admin | :developer | :sales_agent | :support_agent | :read_only | :environment)
        allow!
      in role: Role(:product) if record.product == bearer
        allow!
      in role: Role(:user)
        allow? :upgrade, record, skip_verify_permissions: true, with: ::ReleasePolicy
      in role: Role(:license)
        allow? :upgrade, record, skip_verify_permissions: true, with: ::ReleasePolicy
      else
        record.open? && record.constraints.none?
      end
    end
  end
end

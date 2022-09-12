# frozen_string_literal: true

module Releases::V1x0
  class DownloadPolicy < ApplicationPolicy
    skip_pre_check :verify_authenticated!, only: %i[download? upgrade?]

    def download?
      verify_permissions!('release.download')

      deny! if record.nil?

      case bearer
      in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
        allow!
      in role: { name: 'product' } if record.product == bearer
        allow!
      in role: { name: 'user' }
        allow? :download, record, with: ::ReleasePolicy
      in role: { name: 'license' }
        allow? :download, record, with: ::ReleasePolicy
      else
        record.open_distribution? && record.constraints.none?
      end
    end

    def upgrade?
      verify_permissions!('release.upgrade')

      # Upgrading could result in a nil record, e.g. when no upgrade is available.
      allow! if record.nil?

      case bearer
      in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
        allow!
      in role: { name: 'product' } if record.product == bearer
        allow!
      in role: { name: 'user' }
        allow? :upgrade, record, with: ::ReleasePolicy
      in role: { name: 'license' }
        allow? :upgrade, record, with: ::ReleasePolicy
      else
        record.open_distribution? && record.constraints.none?
      end
    end
  end
end

# frozen_string_literal: true

class ReleasePolicy < ApplicationPolicy
  skip_pre_check :verify_authenticated!, only: %i[index? show? download? upgrade?]

  scope_for :active_record_relation do |relation|
    case bearer
    in role: { name: 'admin' | 'developer' | 'read_only' | 'sales_agent' | 'support_agent' }
      relation.all
    in role: { name: 'product' } if relation.respond_to?(:for_product)
      relation.for_product(bearer.id)
    in role: { name: 'user' } if relation.respond_to?(:for_user)
      relation.for_user(bearer.id)
              .published
    in role: { name: 'license' } if relation.respond_to?(:for_license)
      relation.for_license(bearer.id)
              .published
    else
      relation.open
              .published
    end
  end

  def index?
    verify_permissions!('release.read')

    allow! if
      record.all? { _1.open_distribution? && _1.constraints.none? }

    deny! 'authentication is required' if
      bearer.nil?

    case bearer
    in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
      allow!
    in role: { name: 'product' } if record.all? { _1.product == bearer }
      allow!
    in role: { name: 'user' } if record.all? { _1.open_distribution? && _1.constraints.none? ||
                                               _1.product_id.in?(bearer.product_ids) }
      deny! 'release distribution strategy is closed' if
        record.any?(&:closed_distribution?)

      licenses = bearer.licenses.preload(:product, :policy, :user)
                                .for_product(
                                  record.collect(&:product_id),
                                )

      record.each do |release|
        next if release.open_distribution? &&
                release.constraints.none?

        verify_licenses_for_release!(
          licenses:,
          release:,
        )
      end

      allow!
    in role: { name: 'license' } if record.all? { _1.open_distribution? && _1.constraints.none? ||
                                                  _1.product == bearer.product }
      deny! 'release distribution strategy is closed' if
        record.any?(&:closed_distribution?)

      record.each do |release|
        next if release.open_distribution? &&
                release.constraints.none?

        verify_license_for_release!(
          license: bearer,
          release:,
        )
      end

      allow!
    else
      deny!
    end
  end

  def show?
    verify_permissions!('release.read')

    allow! if
      record.open_distribution? &&
      record.constraints.none?

    deny! 'authentication is required' if
      bearer.nil?

    case bearer
    in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
      allow!
    in role: { name: 'product' } if record.product == bearer
      allow!
    in role: { name: 'user' } if bearer.licenses.for_product(record.product).any?
      deny! 'release distribution strategy is closed' if
        record.closed_distribution?

      licenses = bearer.licenses.preload(:product, :policy, :user)
                                .for_product(record.product)

      verify_licenses_for_release!(
        release: record,
        licenses:,
      )

      allow!
    in role: { name: 'license' } if record.product == bearer.product
      deny! 'release distribution strategy is closed' if
        record.closed_distribution?

      verify_license_for_release!(
        license: bearer,
        release: record,
      )

      allow!
    else
      deny!
    end
  end

  def create?
    verify_permissions!('release.create')

    case bearer
    in role: { name: 'admin' | 'developer' }
      allow!
    in role: { name: 'product' } if record.product == bearer
      allow!
    else
      deny!
    end
  end

  def update?
    verify_permissions!('release.update')

    case bearer
    in role: { name: 'admin' | 'developer' }
      allow!
    in role: { name: 'product' } if record.product == bearer
      allow!
    else
      deny!
    end
  end

  def destroy?
    verify_permissions!('release.delete')

    case bearer
    in role: { name: 'admin' | 'developer' }
      allow!
    in role: { name: 'product' } if record.product == bearer
      allow!
    else
      deny!
    end
  end

  def upgrade?
    verify_permissions!('release.upgrade')

    allow? :show, record, skip_permissions_check: true
  end

  def upload?
    verify_permissions!('release.upload')

    case bearer
    in role: { name: 'admin' | 'developer' }
      allow!
    in role: { name: 'product' } if record.product == bearer
      allow!
    else
      deny!
    end
  end

  def publish?
    verify_permissions!('release.publish')

    case bearer
    in role: { name: 'admin' | 'developer' }
      allow!
    in role: { name: 'product' } if record.product == bearer
      allow!
    else
      deny!
    end
  end

  def yank?
    verify_permissions!('release.yank')

    case bearer
    in role: { name: 'admin' | 'developer' }
      allow!
    in role: { name: 'product' } if record.product == bearer
      allow!
    else
      deny!
    end
  end
end

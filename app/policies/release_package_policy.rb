# frozen_string_literal: true

class ReleasePackagePolicy < ApplicationPolicy
  skip_pre_check :verify_authenticated!

  scope_for :active_record_relation do |relation|
    relation = relation.for_environment(environment, strict: environment.nil?) if
      relation.respond_to?(:for_environment)

    case bearer
    in role: Role(:admin | :developer | :read_only | :sales_agent | :support_agent)
      relation.all
    in role: Role(:environment) if relation.respond_to?(:for_environment)
      relation.for_environment(bearer.id)
    in role: Role(:product) if relation.respond_to?(:for_product)
      relation.for_product(bearer.id)
    in role: Role(:license) if relation.respond_to?(:for_license)
      relation.for_license(bearer.id)
    in role: Role(:user) if relation.respond_to?(:for_user)
      relation.for_user(bearer.id)
    else
      relation.open
    end
  end

  def index?
    verify_permissions!('package.read')
    verify_environment!(
      strict: false,
    )

    case bearer
    in role: Role(:admin | :developer | :sales_agent | :support_agent | :read_only | :environment)
      allow!
    in role: Role(:product) if record.all? { _1.product == bearer }
      allow!
    in role: Role(:user) if record.all? { _1.open? || _1.licensed? && _1.product_id.in?(bearer.product_ids) }
      allow!
    in role: Role(:license) if record.all? { _1.open? || _1.licensed? && _1.product == bearer.product }
      allow!
    in nil if record.all?(&:open?)
      allow!
    else
      deny!
    end
  end

  def show?
    verify_permissions!('package.read')
    verify_environment!(
      strict: false,
    )

    case bearer
    in role: Role(:admin | :developer | :sales_agent | :support_agent | :read_only | :environment)
      allow!
    in role: Role(:product) if record.product == bearer
      allow!
    in role: Role(:user) if record.open? || record.licensed? && bearer.products.exists?(record.product_id)
      allow!
    in role: Role(:license) if record.open? || record.licensed? && record.product == bearer.product
      allow!
    in nil if record.open?
      allow!
    else
      deny!
    end
  end

  def create?
    verify_permissions!('package.create')
    verify_environment!

    case bearer
    in role: Role(:admin | :developer | :environment)
      allow!
    in role: Role(:product) if record.product == bearer
      allow!
    else
      deny!
    end
  end

  def update?
    verify_permissions!('package.update')
    verify_environment!

    case bearer
    in role: Role(:admin | :developer | :environment)
      allow!
    in role: Role(:product) if record.product == bearer
      allow!
    else
      deny!
    end
  end

  def destroy?
    verify_permissions!('package.delete')
    verify_environment!

    case bearer
    in role: Role(:admin | :developer | :environment)
      allow!
    in role: Role(:product) if record.product == bearer
      allow!
    else
      deny!
    end
  end
end

# frozen_string_literal: true

class License::GroupPolicy < ApplicationPolicy
  def show?
    assert_account_scoped!
    assert_authenticated!
    assert_permissions! %w[
      license.group.read
    ]

    resource.context => [License => license]
    resource.subject => Group | nil => group

    bearer.has_role?(:admin, :developer, :sales_agent) ||
      license.product == bearer ||
      (bearer.user? &&
        (license.user == bearer || (group.id == bearer.group_id || group.id.in?(bearer.group_ids)))) ||
      (bearer.license? &&
        license == bearer)
  end

  def update?
    assert_account_scoped!
    assert_authenticated!
    assert_permissions! %w[
      license.group.update
    ]

    resource.context => [License => license]
    resource.subject => Group | nil => group

    bearer.has_role?(:admin, :developer, :sales_agent) ||
      license.product == bearer
  end
end

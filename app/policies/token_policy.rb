# frozen_string_literal: true

class TokenPolicy < ApplicationPolicy

  def index?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      (bearer.has_role?(:product) &&
        # FIXME(ezekg) Eager load licenses and ensure product owns it
        resource.all? { |r| r.bearer_type == License.name || r.bearer_type == bearer.class.name && r.bearer_id == bearer.id }) ||
      (bearer.has_role?(:user, :license) &&
        resource.all? { |r| r.bearer_type == bearer.class.name && r.bearer_id == bearer.id })
  end

  def show?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      resource.bearer == bearer
  end

  def regenerate?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer) ||
      resource.bearer == bearer
  end

  def revoke?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer) ||
      resource.bearer == bearer
  end
end

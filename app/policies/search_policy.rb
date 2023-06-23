# frozen_string_literal: true

class SearchPolicy < ApplicationPolicy
  def search?
    verify_environment!(
      strict: false,
    )

    case bearer
    in role: Role(:admin | :developer | :read_only | :sales_agent | :support_agent)
      allow!
    else
      deny!
    end
  end
end

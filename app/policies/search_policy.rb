# frozen_string_literal: true

class SearchPolicy < ApplicationPolicy
  def search?
    case bearer
    in role: { name: 'admin' | 'developer' | 'read_only' | 'sales_agent' | 'support_agent' }
      allow!
    else
      deny!
    end
  end
end

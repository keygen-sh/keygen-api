# frozen_string_literal: true

module Permissible
  extend ActiveSupport::Concern

  included do
    def can?(*actions)
      permissions.exists?(
        action: actions.flatten << Permission::WILDCARD_PERMISSION,
      )
    end
  end
end

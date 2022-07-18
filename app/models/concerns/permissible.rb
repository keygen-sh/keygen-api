# frozen_string_literal: true

module Permissible
  extend ActiveSupport::Concern

  included do
    def can?(action)
      actions = permissions.collect(&:action)
                           .uniq

      actions.include?(action)
    end
  end
end

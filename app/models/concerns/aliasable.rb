# frozen_string_literal: true

module Aliasable
  extend ActiveSupport::Concern

  class_methods do
    def find_by_alias!(id, aliases:) = FindByAliasService.call(self, id:, aliases:)
    def find_by_alias(...)
      find_by_alias!(...)
    rescue ActiveRecord::RecordNotFound
      nil
    end
  end
end

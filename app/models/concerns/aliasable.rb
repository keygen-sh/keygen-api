# frozen_string_literal: true

module Aliasable
  extend ActiveSupport::Concern

  class_methods do
    cattr_reader :default_aliases, default: Set.new

    def find_by_alias!(id, aliases: default_aliases) = FindByAliasService.call(self, id:, aliases:)
    def find_by_alias(...)
      find_by_alias!(...)
    rescue ActiveRecord::RecordNotFound
      nil
    end

    private

    def has_aliases(*aliases) = default_aliases.merge(aliases)
  end
end

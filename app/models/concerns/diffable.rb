# frozen_string_literal: true

module Diffable
  extend ActiveSupport::Concern

  DIFFABLE_FILTER = %i[password token private key digest]

  included do
    def to_diff
      changeset = previous_changes
      filterer  = ActiveSupport::ParameterFilter.new(DIFFABLE_FILTER, mask: ['[FILTERED]', '[FILTERED]'])
      filtered  = filterer.filter(changeset)

      # Remove '_at' and other suffixes from keys (to match serializers)
      filtered.transform_keys! do |key|
        case
        when key.ends_with?('_digest')
          key.delete_suffix('_digest')
        when key.ends_with?('_at')
          key.delete_suffix('_at')
        else
          key
        end
      end

      filtered
    end
  end
end

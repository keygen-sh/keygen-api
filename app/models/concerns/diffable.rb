# frozen_string_literal: true

module Diffable
  extend ActiveSupport::Concern

  included do
    def to_diff
      filterer  = HashFilter.new(FILTER_KEYS)
      filtered  = filterer.filter(
        previous_changes,
      )

      # FIXME(ezekg) remove '_at' and other suffixes from keys (to match serializers)
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

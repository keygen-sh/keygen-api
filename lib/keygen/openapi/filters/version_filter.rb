# frozen_string_literal: true

module Keygen
  module OpenAPI
    module Filters
      class VersionFilter
        # Filter params based on API version
        def self.filter_params(params, version:)
          params.select do |param|
            applies_to_version?(param, version)
          end
        end

        private

        def self.applies_to_version?(param, version)
          # If no version conditional, applies to all versions
          return true unless param[:if] || param[:unless]

          # Evaluate version conditional
          if param[:if]
            Version::VersionResolver.applies_to_version?(param[:if], version)
          elsif param[:unless]
            !Version::VersionResolver.applies_to_version?(param[:unless], version)
          else
            true
          end
        end
      end
    end
  end
end

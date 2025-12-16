# frozen_string_literal: true

module Keygen
  module OpenAPI
    module Version
      class VersionResolver
        SUPPORTED_VERSIONS = %w[1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7].freeze

        # Evaluate if a conditional applies to a specific version
        def self.applies_to_version?(conditional, version)
          return true unless conditional
          return true unless conditional[:source]

          evaluate_version_conditional(conditional[:source], version)
        end

        def self.evaluate_version_conditional(source, version)
          # Handle .in?() method calls
          if source.include?('.in?')
            evaluate_in_conditional(source, version)
          # Handle comparison operators
          elsif match = source.match(/current_api_version\s*(==|!=|>=|<=|>|<)\s*['"]([^'"]+)['"]/)
            operator = match[1]
            target_version = match[2]
            compare_versions(version, operator, target_version)
          # Handle OR conditions
          elsif source.include?('||')
            evaluate_or_conditional(source, version)
          else
            # If we can't parse it, assume it applies
            true
          end
        end

        def self.evaluate_in_conditional(source, version)
          # Parse: current_api_version.in?(%w[1.0 1.1 1.2])
          # or: current_api_version.in? %w[1.0 1.1 1.2]
          if match = source.match(/\.in\?\s*\(?%w\[([^\]]+)\]/)
            versions = match[1].split(/\s+/)
            versions.include?(version)
          else
            true
          end
        end

        def self.evaluate_or_conditional(source, version)
          # Split by || and evaluate each part
          parts = source.split('||')
          parts.any? { |part| evaluate_version_conditional(part.strip, version) }
        end

        def self.compare_versions(version, operator, target)
          v1 = Gem::Version.new(version)
          v2 = Gem::Version.new(target)

          case operator
          when '=='
            v1 == v2
          when '!='
            v1 != v2
          when '>='
            v1 >= v2
          when '<='
            v1 <= v2
          when '>'
            v1 > v2
          when '<'
            v1 < v2
          else
            true
          end
        rescue ArgumentError
          # If version parsing fails, assume it applies
          true
        end
      end
    end
  end
end

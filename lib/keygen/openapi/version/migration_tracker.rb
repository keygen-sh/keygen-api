# frozen_string_literal: true

module Keygen
  module OpenAPI
    module Version
      class MigrationTracker
        # Track parameter name migrations across API versions
        # Based on config/initializers/request_migrations.rb

        MIGRATIONS = {
          # Example migrations from request_migrations config
          # These would be populated from actual request migrations
          '1.0' => {},
          '1.1' => {},
          '1.2' => {},
          '1.3' => {
            'fingerprint_uniqueness_strategy' => 'machine_uniqueness_strategy',
            'fingerprint_matching_strategy' => 'machine_matching_strategy'
          },
          '1.4' => {},
          '1.5' => {},
          '1.6' => {
            'leasing_strategy' => 'process_leasing_strategy'
          },
          '1.7' => {}
        }.freeze

        # Get the current parameter name for a given version
        def self.current_name(param_name, version)
          # Check if this parameter was migrated in later versions
          MIGRATIONS.each do |migration_version, mappings|
            if Gem::Version.new(version) < Gem::Version.new(migration_version)
              if mappings.key?(param_name)
                return mappings[param_name]
              end
            end
          end

          param_name
        end

        # Check if a parameter is deprecated in a given version
        def self.deprecated?(param_name, version)
          MIGRATIONS.any? do |migration_version, mappings|
            Gem::Version.new(version) >= Gem::Version.new(migration_version) &&
              mappings.key?(param_name)
          end
        end

        # Get the version where a parameter was deprecated
        def self.deprecated_in(param_name)
          MIGRATIONS.each do |version, mappings|
            return version if mappings.key?(param_name)
          end

          nil
        end
      end
    end
  end
end

# frozen_string_literal: true

module Keygen
  module OpenAPI
    module Filters
      class EEFilter
        # Filter out EE-only features from spec
        def self.filter_params(params, edition:)
          return params if edition == :ee

          params.reject do |param|
            is_ee_feature?(param)
          end
        end

        def self.filter_attributes(attributes, edition:)
          return attributes if edition == :ee

          attributes.reject do |attr|
            attr[:ee_only]
          end
        end

        def self.filter_relationships(relationships, edition:)
          return relationships if edition == :ee

          relationships.reject do |rel|
            rel[:ee_only]
          end
        end

        private

        def self.is_ee_feature?(param)
          # Check if param is marked as EE-only
          param[:ee_only] == true
        end
      end
    end
  end
end

# frozen_string_literal: true

module Keygen
  module OpenAPI
    module Writer
      class RefResolver
        def initialize
          @refs = {}
        end

        # Register a reference
        def register(name, category: 'schemas/objects')
          ref_path = "./#{category}/#{name}.yaml"
          @refs[name] = ref_path
          ref_path
        end

        # Get a reference
        def ref(name, category: 'schemas/objects')
          @refs[name] || "./#{category}/#{name}.yaml"
        end

        # Build a $ref object
        def build_ref(name, category: 'schemas/objects')
          { '$ref' => ref(name, category: category) }
        end
      end
    end
  end
end

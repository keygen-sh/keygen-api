# frozen_string_literal: true

require_dependency Rails.root / 'lib' / 'typed_parameters'

TypedParameters.configure do |config|
  config.path_transform = :lower_camel
end

TypedParameters.types.register(:metadata,
  archetype: :hash,
  match: -> value {
    return false unless
      value.is_a?(Hash)

    # Metadata can have one layer of nested arrays/hashes
    value.values.all? { |v|
      case v
      when Hash
        v.values.none? { _1.is_a?(Array) || _1.is_a?(Hash) }
      when Array
        v.none? { _1.is_a?(Array) || _1.is_a?(Hash) }
      else
        true
      end
    }
  },
)

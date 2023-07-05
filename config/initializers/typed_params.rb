# frozen_string_literal: true

TypedParams.configure do |config|
  config.path_transform       = :lower_camel
  config.ignore_nil_optionals = true
end

TypedParams.types.register(:metadata,
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

TypedParams.types.register(:uuid,
  archetype: :string,
  name: 'UUID',
  match: -> value {
    value.is_a?(String) && UUID_RE.match?(value)
  },
)

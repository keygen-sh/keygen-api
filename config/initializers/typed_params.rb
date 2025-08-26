# frozen_string_literal: true

TypedParams.configure do |config|
  config.path_transform       = :lower_camel
  config.ignore_nil_optionals = true
end

TypedParams.types.register(:uuid,
  archetype: :string,
  name: 'UUID',
  match: -> value {
    value.is_a?(String) && UUID_RE.match?(value)
  },
)

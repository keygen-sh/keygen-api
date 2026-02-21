# frozen_string_literal: true

# TODO(ezekg) upstream to typed_params?
class TypedParams::Path
  def to_bracket_notation
    head, *tail = keys

    # transform path [:foo, :bar] to "foo[bar]" for handling query parameters
    "#{head}" + tail.map { transform_key(it) }.reduce(+'') do |s, key|
      s << "[#{key}]"
    end
  end
end

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

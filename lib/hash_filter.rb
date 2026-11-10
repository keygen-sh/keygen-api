# frozen_string_literal: true

require 'active_support/parameter_filter'

# HashFilter extends ActiveSupport::ParameterFilter to replace deep-matching
# hash keys with filtered values using a partial mask, e.g. "abc...xyz", vs
# fully redacting them, preserving enough of the original value and structure
# to aid debugging, e.g. identifying a token or digest, without leaking the
# full secret into things like request or event logs.
#
# In addition to matching on keys, values can be matched via the :values
# option, e.g. to mask a sensitive value that lives under a benign key:
#
#   filterer = HashFilter.new(%i[token], values: [/\Aotpauth:/i])
#   filterer.filter(uri: 'otpauth://totp/Keygen?secret=abc&issuer=Keygen')
#   # => { uri: "otpa...ygen" }
#
class HashFilter < ActiveSupport::ParameterFilter
  EDGE_SIZE = 4
  ELLIPSIS  = '...'
  MIN_SIZE  = EDGE_SIZE * 4 + ELLIPSIS.size

  # the default mask that assumes once matched all nested values are also
  # sensitive values, e.g. an object {tokens:{...}} will mask all values
  # of nested hashes and arrays, while retaining its structure.
  DEFAULT_MASK = ->(value) {
    case value
    when Array
      value.map { DEFAULT_MASK.call(it) }
    when Hash
      value.transform_values { DEFAULT_MASK.call(it) }
    when NilClass, TrueClass, FalseClass
      value # non-sensitive
    else
      # NB(ezekg) coerce any other scalar to a string so it gets masked since
      #           these could be a numeric secret e.g. an OTP, etc.
      s = value.to_s

      case s.size
      when 0..1
        ELLIPSIS # too small (would duplicate s)
      when 2..MIN_SIZE
        "#{s[0]}#{ELLIPSIS}#{s[-1]}"
      else
        "#{s[0, EDGE_SIZE]}#{ELLIPSIS}#{s[-EDGE_SIZE, EDGE_SIZE]}"
      end
    end
  }

  def initialize(filters = [], values: [], mask: DEFAULT_MASK)
    raise ArgumentError, 'mask must be callable' unless
      mask.respond_to?(:call)

    raise ArgumentError, 'values must be regexps' unless
      values.all?(Regexp)

    # NB(ezekg) the parent short-circuits when there are no key filters, so
    #           value filters would otherwise be silently ignored
    raise ArgumentError, 'values cannot be used without filters' if
      filters.empty? && values.any?

    super(filters, mask:)

    @value_re = Regexp.union(values) unless values.empty?
  end

  private

  def value_for_key(key, value, ...)
    filtered_value = super

    # the parent assigns result = @mask when the key matches one of the
    # filters; if our mask is callable, invoke it with the original value
    # to produce a partial mask
    if filtered_value.equal?(@mask) || value_matches?(filtered_value)
      @mask.call(value)
    else
      filtered_value
    end
  end

  # NB(ezekg) the parent recurses into hashes and arrays via value_for_key, so
  #           we only ever need to match scalars, i.e. the leafs. we coerce to
  #           a string to match what the default mask considers sensitive.
  def value_matches?(value)
    return false if
      @value_re.nil?

    case value
    when Hash, Array, NilClass, TrueClass, FalseClass
      false
    else
      @value_re.match?(value.to_s)
    end
  end
end

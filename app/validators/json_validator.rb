# frozen_string_literal: true

class JsonValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?

    if options in maximum_bytesize: Integer => max_bytes
      json = JSON.generate(value)

      unless json.bytesize <= max_bytes
        record.errors.add attribute, :too_long, message: "too large (exceeded limit of #{max_bytes} bytes)"
      end
    end

    if options in maximum_depth: Integer => max_depth
      depth = calculate_depth(value)

      unless depth <= max_depth
        record.errors.add attribute, :too_long, message: "too many items (exceeded limit of #{max_depth} items)"
      end
    end

    if options in maximum_keys: Integer => max_keys
      count = count_keys(value)

      unless count <= max_keys
        record.errors.add attribute, :too_long, message: "too many keys (exceeded limit of #{max_keys} keys)"
      end
    end

    record.errors
  rescue JSON::JSONError
    record.errors.add attribute, :invalid, message: 'must be valid JSON'
  end

  private

  def calculate_depth(value)
    case value
    when Hash
      1 + (value.values.map { calculate_depth(it) }.max || 0)
    when Array
      1 + (value.map { calculate_depth(it) }.max || 0)
    else
      0
    end
  end

  def count_keys(value)
    case value
    when Hash
      value.size + value.values.sum { count_keys(it) }
    when Array
      value.sum { count_keys(it) }
    else
      0
    end
  end
end

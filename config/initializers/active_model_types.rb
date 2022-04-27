# frozen_string_literal: true

class ActiveModel::Type::UUID
  def cast(value)
    value
  end

  def type
    :uuid
  end

  def assert_valid_value(value)
    raise ArgumentError, "#{value.inspect} is not a valid UUID v4" unless
      value.match?(UUID_RE)
  end

  ActiveModel::Type.register(:uuid, self)
end

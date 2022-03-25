class ActiveModel::Type::UUID
  def cast(value)
    value
  end

  def type
    :uuid
  end

  def assert_valid_value(value)
    raise ArgumentError, "#{value.inspect} is not a valid UUID v4" unless
      value.match?(UUID_REGEX)
  end

  ActiveModel::Type.register(:uuid, self)
end

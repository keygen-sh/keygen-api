# frozen_string_literal: true

class ActiveModel::Type::UUID
  def type     = :uuid
  def mutable? = true

  def cast(value)
    value
  end

  def assert_valid_value(value)
    return if
      value.nil?

    raise ArgumentError, "#{value.inspect} is not a valid UUID v4" unless
      value.match?(UUID_RE)
  end

  ActiveModel::Type.register(:uuid, self)
end

class ActiveModel::Type::Array
  def type     = :array
  def mutable? = true

  def cast(value)
    value.to_a
  end

  def assert_valid_value(value)
    return if
      value.nil?

    raise ArgumentError, "#{value.inspect} is not an array" unless
      value.is_a?(Array)
  end

  ActiveModel::Type.register(:array, self)
end

class ActiveModel::Type::Hash
  def type     = :hash
  def mutable? = true

  def cast(value)
    value.to_h
  end

  def assert_valid_value(value)
    return if
      value.nil?

    raise ArgumentError, "#{value.inspect} is not a hash" unless
      value.is_a?(Hash)
  end

  ActiveModel::Type.register(:hash, self)
end

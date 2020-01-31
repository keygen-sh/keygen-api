class Enum < OpenStruct
  def keys
    to_h.keys
  end

  def values
    to_h.values
  end
end

module Enumable
  def define_enum(name, data)
    computed = compute_enum(name, data)

    define_method(name) { computed }
  end
  alias_method :enum, :define_enum

  def define_singleton_enum(name, data)
    computed = compute_enum(name, data)

    define_singleton_method(name) { computed }
  end

  private

  def compute_enum(name, data)
    # Convert possible array to hash (numeric enum)
    data = data.each_with_index.to_h if data.is_a? Array
    computed = Enum.new(data)

    computed
  end
end
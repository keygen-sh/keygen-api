# frozen_string_literal: true

# See: https://gist.github.com/reabiliti/530c2e260468f33b149f2abf5937bae2
RSpec::Matchers.define :deep_include do |expected|
  match do |actual|
    actual = actual.is_a?(OpenStruct) ? actual.to_h : actual

    deep_include?(actual, expected)
  end

  def deep_include?(actual, expected, path = [])
    return true if
      expected === actual

    @failing_expected = expected
    @failing_actual   = actual
    @failing_path     = path

    case actual
    when Array
      Array.wrap(expected).each_with_index do |expected_item, index|
        next if
          actual.any? { |actual_item|
            deep_include?(actual_item, expected_item, path + [index])
          }

        @failing_expected_array_item = expected_item
        @failing_array_path          = path + [index]
        @failing_array               = actual

        return false
      end
    when Hash
      return false unless
        expected.is_a?(Hash)

      expected.all? { |key, expected_value|
        return false unless
          actual.key?(key)

        deep_include?(actual[key], expected_value, path + [key])
      }
    else
      false
    end
  end

  failure_message do |_actual|
    if @failing_array_path
      path = '/' + @failing_array_path.join('/')

      <<~MSG
        Actual array did not include value at #{path}:
          expected:
            #{@failing_expected_array_item.inspect}
          but matching value not found in array:
            #{@failing_array.inspect}
      MSG
    else
      path = '/' + @failing_path.join('/')

      <<~MSG
        Actual hash did not include value at #{path}:
          expected:
            #{@failing_expected.inspect}
          got:
            #{@failing_actual.inspect}
      MSG
    end
  end
end

# frozen_string_literal: true

module TypedParameters
  class HashWithDeepAccess < Hash
    def [](*keys) = dig(*keys)
    def []=(*keys, value)
      key, *rest = keys
      if rest.any?
        v = HashWithDeepAccess.new
        v[*rest] = value

        value = v
      end

      deep_merge!(key => value)
    end
  end
end

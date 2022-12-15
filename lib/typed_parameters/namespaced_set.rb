# frozen_string_literal: true

module TypedParameters
  class NamespacedSet
    def initialize = @store = {}

    def []=(namespace, key, value)
      store.deep_merge!(namespace => { key => value })
    end

    def [](namespace, key)
      _, data = store.find { |k, _| k == namespace } ||
                store.find { |k, _| namespace <= k }

      return nil if
        data.nil?

      data[key]
    end

    def exists?(namespace, key)
      _, data = store.find { |k, _| k == namespace } ||
                store.find { |k, _| namespace <= k }

      return false if
        data.nil?

      data.key?(key)
    end

    private

    attr_reader :store
  end
end

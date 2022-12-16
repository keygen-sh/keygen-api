# frozen_string_literal: true

module TypedParameters
  ##
  # NamespacedSet is a set of key-values that are namespaced by a class.
  # What makes this special is that access supports class inheritance.
  # For example, given a Parent class and a Child class that inherits
  # from Parent, the Child namespace can access the Parent namespace
  # as long as a Child namespace doesn't also exist, in which case
  # it will take precedence.
  #
  # For example, the above, codified:
  #
  #   class Parent; end
  #   class Child < Parent; end
  #
  #   s = NamespacedSet.new
  #   s[Parent, :foo] = :bar
  #
  #   s[Parent, :foo] => :bar
  #   s[Child, :foo] => :bar
  #
  #   s[Child, :baz] = :qux
  #
  #   s[Parent, :baz] => nil
  #   s[Child, :baz] => :qux
  #
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

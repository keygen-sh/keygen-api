# frozen_string_literal: true

require_relative 'namespaced_set'

module TypedParameters
  class HandlerSet
    attr_reader :deferred

    def initialize = @deferred = []

    def deferred? = @deferred.any?

    def params = @params ||= NamespacedSet.new
    def query  = @query  ||= NamespacedSet.new
  end
end

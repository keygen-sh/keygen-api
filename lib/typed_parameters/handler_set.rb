# frozen_string_literal: true

require_relative 'hash_with_deep_access'

module TypedParameters
  class HandlerSet
    attr_reader :deferred

    def initialize = @deferred = []

    def deferred? = @deferred.any?

    def params = @params ||= HashWithDeepAccess.new
    def query  = @query  ||= HashWithDeepAccess.new
  end
end

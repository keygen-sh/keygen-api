# frozen_string_literal: true

module Keygen
  module Database
    class << self
      def read_replica_enabled? = ENV.key?('DATABASE_READ_REPLICA_ENABLED')
    end
  end
end

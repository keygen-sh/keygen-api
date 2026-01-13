# frozen_string_literal: true

module Keygen
  module Database
    class << self
      def config(name = :primary) = ActiveRecord::Base.configurations.configs_for(env_name: Rails.env, name:, include_hidden: true)

      def read_replica_available? = config(:replica)&.host.present?
      def read_replica_enabled?   = ENV.fetch('DATABASE_READ_REPLICA_ENABLED') { '' }.to_bool

      def clickhouse_available? = config(:clickhouse)&.host.present?
      def clickhouse_enabled?   = ENV.fetch('DATABASE_CLICKHOUSE_ENABLED') { '' }.to_bool
    end
  end
end

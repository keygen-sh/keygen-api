# frozen_string_literal: true

module Keygen
  module Database
    class << self
      def config(name = :primary) = ActiveRecord::Base.configurations.configs_for(env_name: Rails.env, name:, include_hidden: true)

      def read_replica_available? = config(:replica)&.host.present?
      def read_replica_enabled?   = ENV.true?('REPLICA_DATABASE_ENABLED')

      def clickhouse_available? = config(:clickhouse)&.host.present?
      def clickhouse_enabled?   = ENV.true?('CLICKHOUSE_DATABASE_ENABLED')
    end
  end
end

# frozen_string_literal: true

# FIXME(ezekg) clickhouse adapter tries to use CURRENT_TIMESTAMP which results in an UNKNOWN_IDENTIFIER error
class ActiveRecord::ConnectionAdapters::ClickhouseAdapter
  module DatabaseStatements
    HIGH_PRECISION_CURRENT_TIMESTAMP = Arel.sql('now64(6)', retryable: true).freeze
    private_constant :HIGH_PRECISION_CURRENT_TIMESTAMP

    def high_precision_current_timestamp = HIGH_PRECISION_CURRENT_TIMESTAMP
  end

  include DatabaseStatements
end

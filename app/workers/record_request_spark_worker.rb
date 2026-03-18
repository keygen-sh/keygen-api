# frozen_string_literal: true

class RecordRequestSparkWorker < BaseWorker
  sidekiq_options queue: :cron,
                  cronitor_enabled: true

  def perform(account_id)
    logs_cte = RequestLog::Clickhouse.where(account_id:, created_date: Date.yesterday)
                                     .where(is_deleted: 0)
                                     .where.not(status: nil)
                                     .select(
                                       :account_id,
                                       :environment_id,
                                       :created_date,
                                       :created_at,
                                       'toUInt16OrZero(status) AS status',
                                     )

    agg_cte = RequestLog::Clickhouse.from('request_log_logs')
                                    .select(
                                      :account_id,
                                      :environment_id,
                                      :created_date,
                                      'max(created_at) AS created_at',
                                      :status,
                                      'count() AS count',
                                    )
                                    .group(
                                      :account_id,
                                      :environment_id,
                                      :created_date,
                                      :status,
                                    )

    RequestSpark.connection.execute(<<~SQL.squish)
      WITH
        request_log_logs AS (#{logs_cte.to_sql}),
        request_log_agg  AS (#{agg_cte.to_sql})
      INSERT INTO request_sparks (
        account_id,
        environment_id,
        created_date,
        created_at,
        status,
        count
      )
      SELECT
        account_id,
        environment_id,
        created_date,
        created_at,
        status,
        count
      FROM
        request_log_agg
    SQL
  end
end

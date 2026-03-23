# frozen_string_literal: true

class RecordEventSparkWorker < BaseWorker
  sidekiq_options queue: :cron,
                  cronitor_enabled: true

  def perform(account_id)
    logs_cte = EventLog.where(account_id:, created_date: Date.yesterday)
                       .select(
                         :account_id,
                         :environment_id,
                         :created_date,
                         :created_at,
                         :event_type_id,
                       )

    agg_cte = EventLog.from('event_log_logs')
                      .select(
                        :account_id,
                        :environment_id,
                        :created_date,
                        'max(created_at) AS created_at',
                        :event_type_id,
                        'count() AS count',
                      )
                      .group(
                        :account_id,
                        :environment_id,
                        :created_date,
                        :event_type_id,
                      )

    EventSpark.connection.execute(<<~SQL.squish)
      WITH
        event_log_logs AS (#{logs_cte.to_sql}),
        event_log_agg  AS (#{agg_cte.to_sql})
      INSERT INTO event_sparks (
        account_id,
        environment_id,
        created_date,
        created_at,
        event_type_id,
        count
      )
      SELECT
        account_id,
        environment_id,
        created_date,
        created_at,
        event_type_id,
        count
      FROM
        event_log_agg
    SQL
  end
end

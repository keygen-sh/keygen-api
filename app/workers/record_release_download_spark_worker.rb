# frozen_string_literal: true

class RecordReleaseDownloadSparkWorker < BaseWorker
  sidekiq_options queue: :cron,
                  cronitor_enabled: true

  def perform(account_id)
    event_type_ids = EventType.by_pattern('artifact.downloaded')
                              .collect(&:id)
    return if
      event_type_ids.empty?

    events_cte = EventLog::Clickhouse.where(account_id:, created_date: Date.yesterday, event_type_id: event_type_ids)
                                     .where('metadata.product IS NOT NULL')
                                     .select(
                                       :account_id,
                                       :environment_id,
                                       :created_date,
                                       :created_at,
                                       'metadata.product.:String AS product_id',
                                       'metadata.package.:String AS package_id',
                                       'metadata.release.:String AS release_id',
                                     )

    agg_cte = EventLog::Clickhouse.from('release_download_events')
                                  .select(
                                    :account_id,
                                    :environment_id,
                                    :created_date,
                                    'max(created_at) AS created_at',
                                    :product_id,
                                    :package_id,
                                    :release_id,
                                    'count() AS count',
                                  )
                                  .group(
                                    :account_id,
                                    :environment_id,
                                    :created_date,
                                    :product_id,
                                    :package_id,
                                    :release_id,
                                  )

    ReleaseDownloadSpark.connection.execute(<<~SQL.squish)
      WITH
        release_download_events AS (#{events_cte.to_sql}),
        release_download_agg    AS (#{agg_cte.to_sql})
      INSERT INTO release_download_sparks (
        account_id,
        environment_id,
        created_date,
        created_at,
        product_id,
        package_id,
        release_id,
        count
      )
      SELECT
        account_id,
        environment_id,
        created_date,
        created_at,
        product_id,
        package_id,
        release_id,
        count
      FROM
        release_download_agg
    SQL
  end
end

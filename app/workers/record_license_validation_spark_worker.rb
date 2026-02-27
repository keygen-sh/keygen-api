# frozen_string_literal: true

class RecordLicenseValidationSparkWorker < BaseWorker
  sidekiq_options queue: :cron,
                  cronitor_enabled: true

  def perform(account_id)
    event_type_ids = EventType.by_pattern('license.validation.*')
                              .collect(&:id)
    return if
      event_type_ids.empty?

    events_cte = EventLog::Clickhouse.where(account_id:, created_date: Date.yesterday, event_type_id: event_type_ids)
                                     .where('metadata.code IS NOT NULL')
                                     .select(
                                       :account_id,
                                       :environment_id,
                                       :created_date,
                                       :created_at,
                                       'resource_id AS license_id',
                                       'metadata.code.:String AS validation_code',
                                     )

    agg_cte = EventLog::Clickhouse.from('license_validation_events')
                                  .select(
                                    :account_id,
                                    :environment_id,
                                    :created_date,
                                    'max(created_at) AS created_at',
                                    :license_id,
                                    :validation_code,
                                    'count() AS count',
                                  )
                                  .group(
                                    :account_id,
                                    :environment_id,
                                    :created_date,
                                    :license_id,
                                    :validation_code,
                                  )

    LicenseValidationSpark.connection.execute(<<~SQL.squish)
      WITH
        license_validation_events AS (#{events_cte.to_sql}),
        license_validation_agg    AS (#{agg_cte.to_sql})
      INSERT INTO license_validation_sparks (
        account_id,
        environment_id,
        created_date,
        created_at,
        license_id,
        validation_code,
        count
      )
      SELECT
        account_id,
        environment_id,
        created_date,
        created_at,
        license_id,
        validation_code,
        count
      FROM
        license_validation_agg
    SQL
  end
end

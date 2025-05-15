class SeedWebhookEndpointForWebhookEvents < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!
  verbose!

  BATCH_SIZE = 1_000

  def up
    update_count = nil
    batch_count  = 0

    until update_count == 0
      batch_count  += 1
      update_count  = exec_update(<<~SQL.squish, batch_count:, batch_size: BATCH_SIZE)
        WITH batch AS (
          SELECT
            webhook_events.id    AS webhook_event_id,
            webhook_endpoints.id AS webhook_endpoint_id
          FROM
            webhook_events
          INNER JOIN
            webhook_endpoints ON webhook_endpoints.account_id     = webhook_events.account_id     AND
                                 webhook_endpoints.environment_id = webhook_events.environment_id AND
                                 webhook_endpoints.url            = webhook_events.endpoint
          WHERE
            webhook_events.webhook_endpoint_id IS NULL
          LIMIT
            :batch_size
        )
        UPDATE
          webhook_events
        SET
          webhook_endpoint_id = batch.webhook_endpoint_id
        FROM
          batch
        WHERE
          webhook_events.id = batch.webhook_event_id
        /* batch=:batch_count */
      SQL
    end
  end

  def down
    update_count = nil
    batch_count  = 0

    until update_count == 0
      batch_count  += 1
      update_count  = exec_update(<<~SQL.squish, batch_count:, batch_size: BATCH_SIZE)
        UPDATE
          webhook_events
        SET
          webhook_endpoint_id = NULL
        WHERE
          webhook_events.id IN (
            SELECT
              webhook_events.id
            FROM
              webhook_events
            WHERE
              webhook_events.webhook_endpoint_id IS NOT NULL
            LIMIT
              :batch_size
          )
        /* batch=:batch_count */
      SQL
    end
  end

  private

  def exec_update(sql, **binds)
    ActiveRecord::Base.connection.exec_update(
      ActiveRecord::Base.sanitize_sql([sql, **binds]),
    )
  end
end

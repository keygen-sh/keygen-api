# heroku run -e BATCH_SIZE=1000000 rails runner db/scripts/seed_api_version_for_webhook_events.rb

BATCH_SIZE = ENV.fetch('BATCH_SIZE') { 1_000 }.to_i

Keygen.logger.info { "[scripts.seed_api_version_for_webhook_events] Starting" }

loop do
  batch ||= 0
  batch  += 1

  count = WebhookEvent.connection.update(<<~SQL.squish)
    UPDATE
      webhook_events AS e1
    SET
      api_version = '1.0'
    WHERE
      e1.id IN (
        SELECT
          id
        FROM
          webhook_events e2
        WHERE
          e2.api_version IS NULL
        LIMIT
          #{BATCH_SIZE}
      )
  SQL

  Keygen.logger.info { "[scripts.seed_api_version_for_webhook_events] Updated #{count} event rows (batch ##{batch})" }

  break if
    count == 0
end

Keygen.logger.info { "[scripts.seed_api_version_for_webhook_events] Done" }

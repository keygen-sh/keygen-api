# heroku run -e BATCH_SIZE=1000000 rails runner db/scripts/seed_v1_api_version_for_webhook_endpoints.rb

BATCH_SIZE = ENV.fetch('BATCH_SIZE') { 1_000 }.to_i

Keygen.logger.info { "[scripts.seed_v1_api_version_for_webhook_endpoints] Starting" }

loop do
  batch ||= 0
  batch  += 1

  count = WebhookEndpoint.connection.update(<<~SQL.squish)
    UPDATE
      webhook_endpoints AS w1
    SET
      api_version = '1.0'
    WHERE
      w1.id IN (
        SELECT
          id
        FROM
          webhook_endpoints w2
        WHERE
          w2.api_version IS NULL
        LIMIT
          #{BATCH_SIZE}
      )
  SQL

  Keygen.logger.info { "[scripts.seed_v1_api_version_for_webhook_endpoints] Updated #{count} endpoint rows (batch ##{batch})" }

  break if
    count == 0
end

Keygen.logger.info { "[scripts.seed_v1_api_version_for_webhook_endpoints] Done" }

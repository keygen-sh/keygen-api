BATCH_SIZE = 100_000
batch = 0

puts "[SeedEventTypeForWebhookEvents] Starting"

loop do
  batch += 1
  count = WebhookEvent.connection.update("
    UPDATE
      webhook_events AS w
    SET
      event_type_id = e.id
    FROM
      event_types AS e
    WHERE
      w.event = e.event AND
      w.id IN (
        SELECT
          id
        FROM
          webhook_events w2
        WHERE
          w2.event_type_id IS NULL
        LIMIT
          #{BATCH_SIZE}
      )
  ")

  puts "[SeedEventTypeForWebhookEvents] Updated #{count} webhook event rows (batch ##{batch})"

  break if count == 0
end

puts "[SeedEventTypeForWebhookEvents] Done"
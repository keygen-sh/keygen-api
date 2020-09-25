# heroku run -e BATCH_SIZE=1000000 rails runner db/scripts/seed_event_type_for_webhook_events.rb

BATCH_SIZE = ENV.fetch('BATCH_SIZE') { 1_000 }.to_i
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
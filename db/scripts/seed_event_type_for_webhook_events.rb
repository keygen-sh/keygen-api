# heroku run -e BATCH_SIZE=1000000 rails runner db/scripts/seed_event_type_for_webhook_events.rb

BATCH_SIZE = ENV.fetch('BATCH_SIZE') { 1_000 }.to_i
batch = 0

puts "[scripts.seed_event_type_for_webhook_events] Starting"

events = EventType.pluck(:event)
conn = WebhookEvent.connection

events.each do |event|
  loop do
    batch += 1
    count = conn.update("
      UPDATE
        webhook_events AS w
      SET
        event_type_id = e.id
      FROM
        event_types AS e
      WHERE
        e.event = '#{event}' AND
        w.id IN (
          SELECT
            id
          FROM
            webhook_events w2
          WHERE
            w2.event_type_id IS NULL AND
            w2.event = '#{event}'
          LIMIT
            #{BATCH_SIZE}
        )
    ")

    puts "[scripts.seed_event_type_for_webhook_events] Updated #{count} webhook event rows for #{event} (batch ##{batch})"

    break if count == 0
  end
end

puts "[scripts.seed_event_type_for_webhook_events] Done"
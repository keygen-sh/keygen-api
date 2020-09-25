# heroku run -e BATCH_SIZE=1000000 rails runner db/scripts/seed_event_type_for_metrics.rb

BATCH_SIZE = ENV.fetch('BATCH_SIZE') { 1_000 }.to_i
batch = 0

puts "[scripts.seed_event_type_for_metrics] Starting"

conn = Metric.connection
events = EventType.pluck(:event)

events.each do |event|
  loop do
    batch += 1
    count = conn.update("
      UPDATE
        metrics AS m
      SET
        event_type_id = e.id
      FROM
        event_types AS e
      WHERE
        e.event = '#{event}' AND
        m.id IN (
          SELECT
            id
          FROM
            metrics m2
          WHERE
            m2.event_type_id IS NULL AND
            m2.metric = '#{event}'
          LIMIT
            #{BATCH_SIZE}
        )
    ")

    puts "[scripts.seed_event_type_for_metrics] Updated #{count} metric rows for #{event} (batch ##{batch})"

    break if count == 0
  end
end

puts "[scripts.seed_event_type_for_metrics] Done"
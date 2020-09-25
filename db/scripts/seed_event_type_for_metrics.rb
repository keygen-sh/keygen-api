BATCH_SIZE = 100_000
batch = 0

puts "[SeedEventTypeForMetrics] Starting"

loop do
  batch += 1
  count = Metric.connection.update("
    UPDATE
      metrics AS m
    SET
      event_type_id = e.id
    FROM
      event_types AS e
    WHERE
      m.metric = e.event AND
      m.id IN (
        SELECT
          id
        FROM
          metrics m2
        WHERE
          m2.event_type_id IS NULL
        LIMIT
          #{BATCH_SIZE}
      )
  ")

  puts "[SeedEventTypeForMetrics] Updated #{count} metric rows (batch ##{batch})"

  break if count == 0
end

puts "[SeedEventTypeForMetrics] Done"
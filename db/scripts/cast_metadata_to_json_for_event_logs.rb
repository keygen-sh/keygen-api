# heroku run:detached -e 'BATCH_SIZE=10000;SLEEP_DURATION=3' rails runner db/scripts/cast_metadata_to_json_for_event_logs.rb --tail

BATCH_SIZE     = ENV.fetch('BATCH_SIZE')     { 1_000 }.to_i
SLEEP_DURATION = ENV.fetch('SLEEP_DURATION') { 1 }.to_i

conn  = EventLog.connection
batch = 0

Rails.logger.info "[scripts.cast_metadata_to_json_for_event_logs] Starting"

# See: https://stackoverflow.com/questions/35372396/accidentally-stored-string-instead-of-object-in-postgres-jsonb-column
loop do
  batch += 1
  count  = conn.update(<<~SQL.squish)
    UPDATE
      event_logs e1
    SET
      metadata = (metadata->>0)::jsonb
    WHERE
      e1.id IN (
        SELECT
          id
        FROM
          event_logs e2
        WHERE
          e2.metadata     IS NOT NULL AND
          e2.metadata->>0 IS NOT NULL
        LIMIT
          #{BATCH_SIZE}
      )
  SQL

  Rails.logger.info "[scripts.cast_metadata_to_json_for_event_logs] Updated #{count} event log rows (batch ##{batch})"

  break if
    count == 0

  sleep SLEEP_DURATION
end

Rails.logger.info "[scripts.cast_metadata_to_json_for_event_logs] Done"

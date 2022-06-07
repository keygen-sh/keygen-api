# heroku run:detached -e BATCH_SIZE=100000 rails runner db/scripts/seed_created_date_for_metrics.rb --tail

BATCH_SIZE = ENV.fetch('BATCH_SIZE') { 10_000 }.to_i

conn  = Metric.connection
batch = 0

Rails.logger.info "[scripts.seed_created_date_for_metrics] Starting"

loop do
  batch += 1
  count = conn.update("
    UPDATE
      metrics m
    SET
      created_date = created_at::date
    WHERE
      m.id IN (
        SELECT
          id
        FROM
          metrics m2
        WHERE
          m2.created_date IS NULL
        LIMIT
          #{BATCH_SIZE}
      )
  ")

  Rails.logger.info "[scripts.seed_created_date_for_metrics] Updated #{count} metric rows (batch ##{batch})"

  break if
    count == 0

  sleep 1
end

Rails.logger.info "[scripts.seed_created_date_for_metrics] Done"

# heroku run -e BATCH_SIZE=1000000 rails runner db/scripts/seed_api_version_for_releases.rb

BATCH_SIZE = ENV.fetch('BATCH_SIZE') { 1_000 }.to_i

Keygen.logger.info { "[scripts.seed_api_version_for_releases] Starting" }

loop do
  batch ||= 0
  batch  += 1

  count = Release.connection.update(<<~SQL.squish)
    UPDATE
      releases AS r1
    SET
      api_version = '1.0'
    WHERE
      r1.id IN (
        SELECT
          id
        FROM
          releases r2
        WHERE
          r2.api_version IS NULL
        LIMIT
          #{BATCH_SIZE}
      )
  SQL

  Keygen.logger.info { "[scripts.seed_api_version_for_releases] Updated #{count} release rows (batch ##{batch})" }

  break if
    count == 0
end

Keygen.logger.info { "[scripts.seed_api_version_for_releases] Done" }

# heroku run -e BATCH_SIZE=1000000 rails runner db/scripts/seed_v1_api_version_for_accounts.rb

BATCH_SIZE = ENV.fetch('BATCH_SIZE') { 1_000 }.to_i

Keygen.logger.info { "[scripts.seed_v1_api_version_for_accounts] Starting" }

loop do
  batch ||= 0
  batch  += 1

  count = Account.connection.update(<<~SQL.squish)
    UPDATE
      accounts AS a1
    SET
      api_version = '1.0'
    WHERE
      a1.id IN (
        SELECT
          id
        FROM
          accounts a2
        WHERE
          a2.api_version IS NULL
        LIMIT
          #{BATCH_SIZE}
      )
  SQL

  Keygen.logger.info { "[scripts.seed_v1_api_version_for_accounts] Updated #{count} account rows (batch ##{batch})" }

  break if
    count == 0
end

Keygen.logger.info { "[scripts.seed_v1_api_version_for_accounts] Done" }

# heroku run -e BATCH_SIZE=100000 rails runner db/scripts/seed_created_date_for_request_logs.rb

BATCH_SIZE = ENV.fetch('BATCH_SIZE') { 10_000 }.to_i
batch = 0

puts "[scripts.seed_created_date_for_request_logs] Starting"

loop do
  batch += 1
  count = RequestLog.connection.update("
    UPDATE
      request_logs
    SET
      created_date = created_at::date
    WHERE
      created_date is null
    LIMIT
      #{BATCH_SIZE}
  ")

  puts "[scripts.seed_created_date_for_request_logs] Updated #{count} request log rows (batch ##{batch})"

  break if count == 0
end

puts "[scripts.seed_created_date_for_request_logs] Done"

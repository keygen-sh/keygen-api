# heroku run:detached -e BATCH_SIZE=100000 rails runner db/scripts/seed_response_signature_for_request_logs.rb --tail

BATCH_SIZE = ENV.fetch('BATCH_SIZE') { 10_000 }.to_i

conn  = RequestLog.connection
batch = 0

Rails.logger.info "[scripts.seed_response_signature_for_request_logs] Starting"

loop do
  batch += 1
  count  = conn.update(<<~SQL.squish)
    INSERT INTO request_log_blobs
      (
        blob_type,
        blob,
        created_at,
        updated_at,
        request_log_id,
        account_id
      )
    SELECT
      'response_signature' AS blob_type,
      l.response_signature AS blob,
      l.created_at         AS created_at,
      l.updated_at         AS updated_at,
      l.id                 AS request_log_id,
      l.account_id         AS account_id
    FROM
      request_logs l
    LEFT OUTER JOIN
      request_log_blobs b ON b.blob_type      = 'response_signature' AND
                             b.request_log_id = l.id
    WHERE
      b.id IS NULL
    LIMIT
      #{BATCH_SIZE}
  SQL

  Rails.logger.info "[scripts.seed_response_signature_for_request_logs] Updated #{count} request log rows (batch ##{batch})"

  break if
    count == 0

  sleep 1
end

Rails.logger.info "[scripts.seed_response_signature_for_request_logs] Done"

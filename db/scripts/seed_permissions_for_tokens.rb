# heroku run:detached -e 'BATCH_SIZE=10000;SLEEP_DURATION=3' rails runner db/scripts/seed_permissions_for_tokens.rb --tail

BATCH_SIZE     = ENV.fetch('BATCH_SIZE')     { 1_000 }.to_i
SLEEP_DURATION = ENV.fetch('SLEEP_DURATION') { 1 }.to_f

Rails.logger.info "[scripts.seed_permissions_for_tokens] Starting"

Token.find_in_batches(batch_size: BATCH_SIZE) do |tokens|
  tokens.each do |token|
    token.update!(permissions: token.default_permission_ids)

    sleep SLEEP_DURATION / 10
  end

  sleep SLEEP_DURATION
end

Rails.logger.info "[scripts.seed_permissions_for_tokens] Done"

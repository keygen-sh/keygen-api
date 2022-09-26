# heroku run:detached -e 'BATCH_SIZE=10000;SLEEP_DURATION=3' rails runner db/scripts/seed_permissions_for_tokens.rb --tail

BATCH_SIZE     = ENV.fetch('BATCH_SIZE')     { 1_000 }.to_i
SLEEP_DURATION = ENV.fetch('SLEEP_DURATION') { 1 }.to_f

Rails.logger.info "[scripts.seed_permissions_for_tokens] Starting"

tokens      = Token.where.missing(:token_permissions)
batch_count = 0
token_count = 0

Rails.logger.info "[scripts.seed_permissions_for_tokens] Seeding #{tokens.count} tokens"

tokens.find_in_batches(batch_size: BATCH_SIZE) do |batch|
  batch_count += 1

  Rails.logger.info "[scripts.seed_permissions_for_tokens] Seeding batch ##{batch_count} of #{batch.size} tokens"

  batch.each do |token|
    token_count += 1

    token.reset_permissions!

    sleep SLEEP_DURATION / 10
  end

  sleep SLEEP_DURATION
end

Rails.logger.info "[scripts.seed_permissions_for_tokens] Seeded #{token_count} tokens"

Rails.logger.info "[scripts.seed_permissions_for_tokens] Done"

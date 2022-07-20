# heroku run:detached -e 'BATCH_SIZE=10000;SLEEP_DURATION=3' rails runner db/scripts/seed_permissions_for_roles.rb --tail

BATCH_SIZE     = ENV.fetch('BATCH_SIZE')     { 1_000 }.to_i
SLEEP_DURATION = ENV.fetch('SLEEP_DURATION') { 1 }.to_f

Rails.logger.info "[scripts.seed_permissions_for_roles] Starting"

Role.find_in_batches(batch_size: BATCH_SIZE) do |roles|
  roles.each {
    _1.send(:set_default_permissions!)

    sleep SLEEP_DURATION / 10
  }

  sleep SLEEP_DURATION
end

Rails.logger.info "[scripts.seed_permissions_for_roles] Done"

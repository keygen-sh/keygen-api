# heroku run:detached rails runner db/scripts/seed_backend_for_accounts.rb --tail

Rails.logger.info { "[scripts.seed_backend_for_accounts] Starting" }

count = Account.update_all(backend: 'S3')

Rails.logger.info { "[scripts.seed_backend_for_accounts] Seeded backend for #{count} accounts" }
Rails.logger.info { "[scripts.seed_backend_for_accounts] Done" }

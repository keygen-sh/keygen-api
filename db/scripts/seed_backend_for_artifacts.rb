# heroku run:detached rails runner db/scripts/seed_backend_for_artifacts.rb --tail

Rails.logger.info { "[scripts.seed_backend_for_artifacts] Starting" }

count = ReleaseArtifact.update_all(backend: 'S3')

Rails.logger.info { "[scripts.seed_backend_for_artifacts] Seeded backend for #{count} artifacts" }
Rails.logger.info { "[scripts.seed_backend_for_artifacts] Done" }

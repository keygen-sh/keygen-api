# heroku run rails runner db/scripts/seed_status_for_release_artifacts.rb

Keygen.logger.info { "[scripts.seed_status_for_release_artifacts] Starting" }

count = ReleaseArtifact.update_all(status: 'UPLOADED')

Keygen.logger.info { "[scripts.seed_status_for_release_artifacts] Seeded status for #{count} artifact rows" }
Keygen.logger.info { "[scripts.seed_status_for_release_artifacts] Done" }

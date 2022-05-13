# heroku run rails runner db/scripts/seed_status_for_releases.rb

Keygen.logger.info { "[scripts.seed_status_for_releases] Starting" }

draft_count     = Release.where(yanked_at: nil).without_artifacts.update_all(status: 'DRAFT')
published_count = Release.where(yanked_at: nil).with_artifacts.update_all(status: 'PUBLISHED')
yanked_count    = Release.where.not(yanked_at: nil).update_all(status: 'YANKED')

Keygen.logger.info { "[scripts.seed_status_for_releases] Seeded status for #{draft_count} draft release rows" }
Keygen.logger.info { "[scripts.seed_status_for_releases] Seeded status for #{published_count} published release rows" }
Keygen.logger.info { "[scripts.seed_status_for_releases] Seeded status for #{yanked_count} yanked release rows" }

Keygen.logger.info { "[scripts.seed_status_for_releases] Done" }

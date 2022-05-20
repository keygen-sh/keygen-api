# heroku run rails runner db/scripts/seed_semver_for_releases.rb

Keygen.logger.info { "[scripts.seed_semver_for_releases] Starting" }

count = 0

Release.where(semver_major: nil, semver_minor: nil, semver_patch: nil).find_each do |release|
  release.send(:set_semver_version)
  release.save(validate: false)

  count += 1
end

Keygen.logger.info { "[scripts.seed_semver_for_releases] Seeded semver for #{count} release rows" }

Keygen.logger.info { "[scripts.seed_semver_for_releases] Done" }

# heroku run -e BATCH_SIZE=1000000 rails runner db/scripts/seed_info_for_release_artifacts.rb

BATCH_SIZE = ENV.fetch('BATCH_SIZE') { 1_000 }.to_i

Keygen.logger.info { "[scripts.seed_info_for_release_artifacts] Starting" }

Release.with_artifacts.find_each do |release|
  count = ReleaseArtifact.where(release:).update_all(
    release_platform_id: release.release_platform_id,
    release_filetype_id: release.release_filetype_id,
    filename: release.filename,
    filesize: release.filesize,
    signature: release.signature,
    checksum: release.checksum,
  )

  Keygen.logger.info { "[scripts.seed_info_for_release_artifacts] Seeded #{count} artifact row(s) for release #{release.id}" }

  sleep 0.1
end

Keygen.logger.info { "[scripts.seed_info_for_release_artifacts] Done" }

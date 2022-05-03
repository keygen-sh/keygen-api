# heroku run rails runner db/scripts/seed_info_for_release_artifacts.rb

Keygen.logger.info { "[scripts.seed_info_for_release_artifacts] Starting" }

count = ReleaseArtifact.connection.update(<<~SQL.squish)
  UPDATE
    release_artifacts a
  SET
    release_platform_id = r.release_platform_id,
    release_filetype_id = r.release_filetype_id,
    filename            = r.filename,
    filesize            = r.filesize,
    signature           = r.signature,
    checksum            = r.checksum
  FROM
    releases r
  WHERE
    a.release_id = r.id
SQL

Keygen.logger.info { "[scripts.seed_info_for_release_artifacts] Seeded data for #{count} artifact rows" }
Keygen.logger.info { "[scripts.seed_info_for_release_artifacts] Done" }

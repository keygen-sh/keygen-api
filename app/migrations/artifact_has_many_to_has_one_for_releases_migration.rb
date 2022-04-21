# frozen_string_literal: true

class ArtifactHasManyToHasOneForReleasesMigration < Versionist::Migration
  description "transforms a collection of Releases' artifacts from has-many to has-one relationships"

  routes :v1_account_releases,
         :v1_account_product_releases

  response do |res|
    next unless
      res.successful?

    body = JSON.parse(res.body, symbolize_names: true)
    data = body[:data]

    account_id  = data[0][:relationships][:account][:data][:id]
    release_ids = data.collect { |release| release[:id] }

    # Preload artifacts so we don't introduce any N+1 queries
    artifacts = ReleaseArtifact.where(
      release_id: release_ids,
      account_id:,
    )

    data.each do |release|
      release_id = release[:id]
      artifact   = artifacts.find { |a| a.release_id == release_id }

      release[:relationships].tap do |rels|
        rels[:artifact] = {
          data: artifact.present? ? { type: 'artifacts', id: artifact.id } : nil,
          links: { related: v1_account_release_legacy_artifact_path(account_id, release_id) },
        }

        rels.delete(:artifacts)
      end
    end

    res.body = JSON.generate(body)
  end
end

# frozen_string_literal: true

class ArtifactHasManyToHasOneForReleaseMigration < Versionist::Migration
  description "transforms a Release's artifacts from a has-many to has-one relationship"

  routes :v1_account_release,
         :v1_account_product_release

  response do |res|
    next unless
      res.successful?

    body = JSON.parse(res.body, symbolize_names: true)
    data = body[:data]

    account_id = data[:relationships][:account][:data][:id]
    release_id = data[:id]

    artifact = ReleaseArtifact.find_by(
      release_id:,
      account_id:,
    )

    data[:relationships].tap do |rels|
      rels[:artifact] = {
        data: artifact.present? ? { type: 'artifacts', id: artifact.id } : nil,
        links: { related: v1_account_release_legacy_artifact_path(account_id, release_id) },
      }

      rels.delete(:artifacts)
    end

    res.body = JSON.generate(body)
  end
end

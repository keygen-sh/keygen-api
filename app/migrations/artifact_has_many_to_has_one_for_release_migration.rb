# frozen_string_literal: true

class ArtifactHasManyToHasOneForReleaseMigration < Versionist::Migration
  description "transforms a Release's artifacts from a has-many to has-one relationship"

  migrate if: -> body { body in data: { ** } } do |body|
    case body
    in data: { type: 'releases', id: release_id, relationships: { account: { data: { type: 'accounts', id: account_id } } } }
      artifact = ReleaseArtifact.find_by(release_id:, account_id:)

      body[:data][:relationships].tap do |rels|
        rels[:artifact] = {
          data: artifact.present? ? { type: 'artifacts', id: artifact.id } : nil,
          links: {
            related: v1_account_release_legacy_artifact_path(account_id, release_id),
          },
        }

        rels.delete(:artifacts)
      end
    else
    end
  end

  response if: -> res { res.request.params in controller: 'api/v1/releases' | 'api/v1/products/relationships/releases', action: 'show' | 'create' | 'upsert' | 'update' } do |res|
    next unless
      res.successful?

    body = JSON.parse(res.body, symbolize_names: true)

    migrate!(body)

    res.body = JSON.generate(body)
  end
end

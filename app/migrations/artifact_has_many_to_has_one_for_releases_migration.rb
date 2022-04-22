# frozen_string_literal: true

class ArtifactHasManyToHasOneForReleasesMigration < Versionist::Migration
  description "transforms a collection of Releases' artifacts from has-many to has-one relationships"

  migrate if: -> body { body in data: [*] } do |body|
    case body
    in data: [*, { type: 'releases', id: _, relationships: { account: { data: { type: 'accounts', id: _ } } } }, *]
      account_ids = body[:data].collect { _1[:relationships][:account][:data][:id] }.compact.uniq
      release_ids = body[:data].collect { _1[:id] }.compact.uniq

      artifacts = ReleaseArtifact.distinct_on(:release_id)
                                 .select(:id)
                                 .where(account_id: account_ids, release_id: release_ids)
                                 .reorder(:release_id, created_at: :desc)
                                 .group_by(&:release_id)

      body[:data].each do |release|
        case release
        in type: 'releases', id: release_id, relationships: { account: { data: { type: 'accounts', id: account_id } } }
          artifact = artifacts[release_id]&.first

          release[:relationships].tap do |rels|
            rels[:artifact] = {
              data: artifact.present? ? { type: 'artifacts', id: artifact.id } : nil,
              links: {
                related: v1_account_release_legacy_artifact_path(account_id, release_id),
              },
            }

            rels.delete(:artifacts)
          end
        end
      end
    else
    end
  end

  response if: -> res { res.request.params in controller: 'api/v1/releases' | 'api/v1/products/relationships/releases', action: 'index' } do |res|
    next unless
      res.successful?

    data = JSON.parse(res.body, symbolize_names: true)

    migrate!(data)

    res.body = JSON.generate(data)
  end
end

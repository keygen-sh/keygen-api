# frozen_string_literal: true

class ArtifactHasManyToHasOneForReleasesMigration < BaseMigration
  description %(transforms a collection of Releases' artifacts from has-many to has-one relationships)

  migrate if: -> body { body in data: [*] } do |body|
    case body
    in data: [*, { type: /\Areleases\z/, id: _, relationships: { account: { data: { type: /\Aaccounts\z/, id: _ } }, artifacts: { ** } } }, *]
      account_ids = body[:data].collect { _1[:relationships][:account][:data][:id] }.compact.uniq
      release_ids = body[:data].collect { _1[:id] }.compact.uniq

      artifacts = ReleaseArtifact.distinct_on(:release_id)
                                 .select(:id, :release_id)
                                 .where(account_id: account_ids, release_id: release_ids)
                                 .reorder(:release_id, created_at: :desc)
                                 .group_by(&:release_id)

      body[:data].each do |release|
        case release
        in type: /\Areleases\z/, id: release_id, relationships: { account: { data: { type: /\Aaccounts\z/, id: account_id } } }
          artifact = artifacts[release_id]&.first

          release[:relationships].tap do |rels|
            rels[:artifact] = {
              data: artifact.present? ? { type: :artifacts, id: artifact.id } : nil,
              links: {
                related: v1_account_release_v1_0_release_artifact_path(account_id, release_id),
              },
            }

            rels.delete(:artifacts)
          end
        end
      end
    else
    end
  end

  response if: -> res { res.status < 400 && res.request.params in controller: 'api/v1/releases' | 'api/v1/products/relationships/releases',
                                                                  action: 'index' } do |res|
    body = JSON.parse(res.body, symbolize_names: true)

    migrate!(body)

    res.body = JSON.generate(body)
  end
end

# frozen_string_literal: true

class ArtifactHasManyToHasOneForReleasesMigration < Versionist::Migration[1.1]
  description "transforms a collection of Releases' artifacts from has-many to has-one relationships"

  routes :v1_account_releases,
         :v1_account_product_releases

  transform do |data|
    next unless
      data.present?

    case data
    in data: [*, { type: 'releases' }, *]
      data[:data].each do |release|
        case release
        in type: 'releases', id: release_id, relationships: { account: { data: { type: 'accounts', id: account_id } } }
          # FIXME(ezekg) N+1 query
          artifact = ReleaseArtifact.find_by(account_id:, release_id:)

          release[:relationships].tap do |rels|
            rels[:artifact] = {
              data: artifact.present? ? { type: 'artifacts', id: artifact.id } : nil,
              links: { related: url_helpers.v1_account_release_legacy_artifact_path(account_id, release_id) },
            }

            rels.delete(:artifacts)
          end
        end
      end
    end

    data
  end

  response do |res|
    next unless
      res.successful?

    data = JSON.parse(res.body, symbolize_names: true)

    transform!(data)

    res.body = JSON.generate(data)
  end
end

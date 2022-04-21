# frozen_string_literal: true

class ArtifactHasManyToHasOneForReleasesMigration < Versionist::Migration[1.1]
  description "transforms a collection of Releases' artifacts from has-many to has-one relationships"

  routes :v1_account_releases,
         :v1_account_product_releases

  transform do |data|
    next unless
      data.present?

    case data
    in data: [*, { type: 'releases', id: _, relationships: { account: { data: { type: 'accounts', id: _ } } } }, *]
      account_ids = data[:data].collect { _1[:relationships][:account][:data][:id] }.compact.uniq
      release_ids = data[:data].collect { _1[:id] }.compact.uniq

      artifacts = ReleaseArtifact.distinct_on(:release_id)
                                 .where(account_id: account_ids, release_id: release_ids)
                                 .reorder(:release_id, created_at: :desc)
                                 .group_by(&:release_id)

      data[:data].each do |release|
        case release
        in type: 'releases', id: release_id, relationships: { account: { data: { type: 'accounts', id: account_id } } }
          artifact = artifacts[release_id]&.first

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

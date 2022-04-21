# frozen_string_literal: true

class ArtifactHasManyToHasOneForReleaseMigration < Versionist::Migration[1.1]
  description "transforms a Release's artifacts from a has-many to has-one relationship"

  routes :v1_account_release,
         :v1_account_product_release

  transform do |data|
    next unless
      data.present?

    case data
    in data: { type: 'releases', id: release_id, relationships: { account: { data: { type: 'accounts', id: account_id } } } }
      artifact = ReleaseArtifact.find_by(
        release_id:,
        account_id:,
      )

      data[:data][:relationships].tap do |rels|
        rels[:artifact] = {
          data: artifact.present? ? { type: 'artifacts', id: artifact.id } : nil,
          links: { related: url_helpers.v1_account_release_legacy_artifact_path(account_id, release_id) },
        }

        rels.delete(:artifacts)
      end
    end

    data
  end

  response do |res|
    return unless
      res.present? && res.successful?

    data = JSON.parse(res.body, symbolize_names: true)

    transform!(data)

    res.body = JSON.generate(data)
  end
end

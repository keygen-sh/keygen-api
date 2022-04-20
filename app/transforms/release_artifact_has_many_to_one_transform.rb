# frozen_string_literal: true

class ReleaseArtifactHasManyToOneTransform < Versionist::Transform
  description 'transforms release#artifacts from has_many to has_one'

  routes :v1_account_releases,
         :v1_account_release,
         :v1_account_product_releases,
         :v1_account_product_release

  response do |res|
    next unless
      res.successful?

    body = JSON.parse(res.body, symbolize_names: true)
    data = body[:data]

    # FIXME(ezekg) This should be 2 separate transforms
    case data
    when Array
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
    when Hash
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
    end

    res.body = JSON.generate(body)
  end
end

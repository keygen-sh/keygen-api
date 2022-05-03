# frozen_string_literal: true

class ArtifactAttributesToReleaseMigration < BaseMigration
  description %(moves Artifact attributes to a Release)

  migrate if: -> body { body in data: { ** } } do |body|
    case body
    in data: { type: /\Areleases\z/, id: release_id, relationships: { account: { data: { type: /\Aaccounts\z/, id: account_id } }, artifacts: { ** } } }
      artifact = ReleaseArtifact.preload(:platform, :filetype)
                                .find_by(release_id:, account_id:)

      body[:data][:attributes].tap do |attrs|
        attrs.merge!(
          platform: artifact&.platform&.key,
          filetype: artifact&.filetype&.key,
          filename: artifact&.filename,
          filesize: artifact&.filesize,
          signature: artifact&.signature,
          checksum: artifact&.checksum,
        )
      end
    else
    end
  end

  response if: -> res { res.successful? && res.request.params in controller: 'api/v1/releases' | 'api/v1/products/relationships/releases', action: 'show' | 'create' | 'upsert' | 'update' } do |res|
    data = JSON.parse(res.body, symbolize_names: true)

    migrate!(data)

    res.body = JSON.generate(data)
  end
end

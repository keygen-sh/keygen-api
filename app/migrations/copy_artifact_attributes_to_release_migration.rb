# frozen_string_literal: true

class CopyArtifactAttributesToReleaseMigration < BaseMigration
  description %(copies Artifact attributes onto a Release)

  migrate if: -> body { body in data: { ** } } do |body|
    case body
    in data: { type: /\Areleases\z/, id: release_id, attributes: { ** }, relationships: { account: { data: { type: /\Aaccounts\z/, id: account_id } } } }
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

  response if: -> res { res.status < 400 && res.request.params in controller: 'api/v1/releases' | 'api/v1/products/relationships/releases',
                                                                  action: 'show' | 'create' | 'update' } do |res|
    body = JSON.parse(res.body, symbolize_names: true)

    migrate!(body)

    res.body = JSON.generate(body)
  end
end

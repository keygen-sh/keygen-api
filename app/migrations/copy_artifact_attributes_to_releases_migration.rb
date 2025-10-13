# frozen_string_literal: true

class CopyArtifactAttributesToReleasesMigration < BaseMigration
  description %(copies Artifact attributes onto a collection of Releases)

  migrate if: -> body { body in data: [*] } do |body|
    case body
    in data: [*, { type: /\Areleases\z/, id: _, attributes: { ** }, relationships: { account: { data: { type: /\Aaccounts\z/, id: _ } } } }, *]
      account_ids = body[:data].collect { it[:relationships][:account][:data][:id] }.compact.uniq
      release_ids = body[:data].collect { it[:id] }.compact.uniq

      artifacts = ReleaseArtifact.preload(:platform, :filetype)
                                 .distinct_on(:release_id)
                                 .where(account_id: account_ids, release_id: release_ids)
                                 .reorder(:release_id, created_at: :desc)
                                 .group_by(&:release_id)

      body[:data].each do |release|
        case release
        in type: /\Areleases\z/, id: release_id, attributes: { ** }
          artifact = artifacts[release_id]&.first

          release[:attributes].tap do |attrs|
            attrs.merge!(
              platform: artifact&.platform&.key,
              filetype: artifact&.filetype&.key,
              filename: artifact&.filename,
              filesize: artifact&.filesize,
              signature: artifact&.signature,
              checksum: artifact&.checksum,
            )
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

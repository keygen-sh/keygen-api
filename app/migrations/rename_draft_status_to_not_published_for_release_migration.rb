# frozen_string_literal: true

class RenameDraftStatusToNotPublishedForReleaseMigration < BaseMigration
  description %(renames the DRAFT status to NOT_PUBLISHED for a Release)

  migrate if: -> body { body in data: { ** } } do |body|
    case body
    in data: { type: /\Areleases\z/, id: release_id, attributes: { status: 'DRAFT' }, relationships: { account: { data: { type: /\Aaccounts\z/, id: account_id } } } }
      artifact = ReleaseArtifact.preload(:platform, :filetype)
                                .find_by(release_id:, account_id:)

      body[:data][:attributes].tap do |attrs|
        attrs[:status] = 'NOT_PUBLISHED'
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

# frozen_string_literal: true

class RenameDraftStatusToNotPublishedForReleasesMigration < BaseMigration
  description %(renames the DRAFT statuses to NOT_PUBLISHED for a collection Releases)

  migrate if: -> body { body in data: [*] } do |body|
    case body
    in data: [*, { type: /\Areleases\z/, id: _, attributes: { status: 'DRAFT' }, relationships: { account: { data: { type: /\Aaccounts\z/, id: _ } } } }, *]
      account_ids = body[:data].collect { _1[:relationships][:account][:data][:id] }.compact.uniq
      release_ids = body[:data].collect { _1[:id] }.compact.uniq

      artifacts = ReleaseArtifact.distinct_on(:release_id)
                                 .select(:id, :release_id)
                                 .where(account_id: account_ids, release_id: release_ids)
                                 .reorder(:release_id, created_at: :desc)
                                 .group_by(&:release_id)

      body[:data].each do |release|
        case release
        in type: /\Areleases\z/, id: release_id, attributes: { status: 'DRAFT' }
          artifact = artifacts[release_id]&.first

          release[:attributes].tap do |attrs|
            attrs[:status] = 'NOT_PUBLISHED'
          end
        else
        end
      end
    else
    end
  end

  response if: -> res { res.successful? && res.request.params in controller: 'api/v1/releases' | 'api/v1/products/relationships/releases', action: 'index' } do |res|
    data = JSON.parse(res.body, symbolize_names: true)

    migrate!(data)

    res.body = JSON.generate(data)
  end
end

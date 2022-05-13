# frozen_string_literal: true

class RenameDraftStatusToNotPublishedForReleasesMigration < BaseMigration
  description %(renames the DRAFT statuses to NOT_PUBLISHED for a collection of Releases)

  migrate if: -> body { body in data: [*] } do |body|
    case body
    in data: [*, { type: /\Areleases\z/, attributes: { status: 'DRAFT' } }, *]
      body[:data].each do |release|
        case release
        in type: /\Areleases\z/, attributes: { status: 'DRAFT' }
          release[:attributes][:status] = 'NOT_PUBLISHED'
        else
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

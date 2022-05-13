# frozen_string_literal: true

class RenameDraftStatusToNotPublishedForReleaseMigration < BaseMigration
  description %(renames the DRAFT status to NOT_PUBLISHED for a Release)

  migrate if: -> body { body in data: { ** } } do |body|
    case body
    in data: { type: /\Areleases\z/, attributes: { status: 'DRAFT' } }
      body[:data][:attributes][:status] = 'NOT_PUBLISHED'
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

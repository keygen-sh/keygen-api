# frozen_string_literal: true

class AddConcurrentAttributeToPolicyMigration < BaseMigration
  description %(adds concurrent attribute to a Policy)

  migrate if: -> body { body in data: { ** } } do |body|
    case body
    in data: { type: /\Apolicies\z/, attributes: { overageStrategy: overage_strategy } }
      body[:data][:attributes][:concurrent] = overage_strategy != 'NO_OVERAGE'
    else
    end
  end

  response if: -> res { res.status < 400 && res.request.params in controller: 'api/v1/policies' | 'api/v1/licenses/relationships/policies' | 'api/v1/keys/relationships/policies' | 'api/v1/products/relationships/policies',
                                                                  action: 'show' | 'create' | 'update' } do |res|
    body = JSON.parse(res.body, symbolize_names: true)

    migrate!(body)

    res.body = JSON.generate(body)
  end
end

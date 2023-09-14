# frozen_string_literal: true

class AddConcurrentAttributeToPoliciesMigration < BaseMigration
  description %(adds concurrent attributes to a collection of Policies)

  migrate if: -> body { body in included: [*] } do |body|
    case body
    in included: [*, { type: /\Apolicies\z/, attributes: { ** } }, *] => includes
      includes.each do |record|
        case record
        in type: /\Apolicies\z/, attributes: { overageStrategy: overage_strategy } => attrs
          attrs[:concurrent] = overage_strategy != 'NO_OVERAGE'
        else
        end
      end
    else
    end
  end

  migrate if: -> body { body in data: [*] } do |body|
    case body
    in data: [*, { type: /\Apolicies\z/, attributes: { ** } }, *] => data
      data.each do |policy|
        case policy
        in type: /\Apolicies\z/, attributes: { overageStrategy: overage_strategy } => attrs
          attrs[:concurrent] = overage_strategy != 'NO_OVERAGE'
        else
        end
      end
    else
    end
  end

  response if: -> res { res.status < 400 && res.request.params in controller: 'api/v1/policies' | 'api/v1/licenses/relationships/policies' | 'api/v1/keys/relationships/policies' | 'api/v1/products/relationships/policies',
                                                                  action: 'index' } do |res|
    body = JSON.parse(res.body, symbolize_names: true)

    migrate!(body)

    res.body = JSON.generate(body)
  end
end

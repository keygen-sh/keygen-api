# frozen_string_literal: true

class RenameMachineMatchingStrategyToFingerprintMatchingStrategyForPolicyMigration < BaseMigration
  description %(renames machine matching strategy to fingerprint matching strategy for a Policy)

  migrate if: -> body { body in data: { ** } } do |body|
    body => data:

    case data
    in type: /\Apolicies\z/, attributes: { machineMatchingStrategy: String } => attrs
      attrs[:fingerprintMatchingStrategy] = attrs.delete(:machineMatchingStrategy)
    else
    end
  end

  response if: -> res { res.status < 400 && res.request.params in controller: 'api/v1/policies' | 'api/v1/products/relationships/policies' | 'api/v1/licenses/relationships/policies',
                                                                  action: 'show' | 'create' | 'update' } do |res|
    body = JSON.parse(res.body, symbolize_names: true)

    migrate!(body)

    res.body = JSON.generate(body)
  end
end

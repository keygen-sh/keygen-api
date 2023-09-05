# frozen_string_literal: true

class RenameMachineUniquenessStrategyToFingerprintUniquenessStrategyForPolicyMigration < BaseMigration
  description %(renames machine uniqueness strategy to fingerprint uniqueness strategy for a Policy)

  migrate if: -> body { body in data: { ** } } do |body|
    body => data:

    case data
    in type: /\Apolicies\z/, attributes: { machineUniquenessStrategy: String } => attrs
      attrs[:fingerprintUniquenessStrategy] = attrs.delete(:machineUniquenessStrategy)
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
